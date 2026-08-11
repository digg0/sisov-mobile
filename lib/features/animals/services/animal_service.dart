import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/db/local_cache.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/api_error_messages.dart';
import '../models/management_event_model.dart';
import '../models/slaughter_registration_model.dart';

class AnimalService {
  final _cache = LocalCache.instance;

  Future<Map<String, dynamic>> createAnimal(
    Map<String, dynamic> animalData,
  ) async {
    final localId = SyncService.newLocalId();
    final optimistic = {
      ...animalData,
      'sisovId': localId,
      'status': 'ACTIVE',
      'syncStatus': 'PENDING',
    };
    await _cache.upsertAnimal(optimistic);

    final result = await SyncService.instance.submitWrite(
      endpoint: '/animals',
      payload: animalData,
      label: 'Cadastro de animal',
      entityType: 'animal',
      localEntityId: localId,
    );

    // Servidor recusou (validação etc.): remove o rascunho local.
    if (result['success'] != true) {
      await _cache.deleteAnimal(localId);
    }

    return {...result, 'localEntityId': localId};
  }

  Future<Map<String, dynamic>> getAnimal(String identifier) async {
    try {
      final response = await ApiClient.get('/animals/$identifier');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final animal = decoded is Map && decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : null;
        if (animal != null) {
          await _cache.upsertAnimal(animal);
          return {'success': true, 'data': animal};
        }
        return {'success': true, 'data': decoded};
      }

      final localOnError = await _cache.getAnimal(identifier);
      if (localOnError != null) {
        return {'success': true, 'data': localOnError, 'fromCache': true};
      }

      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
          action: ApiAction.generic,
        ),
      };
    } catch (_) {
      // Offline: tenta cache local.
    }

    final local = await _cache.getAnimal(identifier);
    if (local != null) {
      return {'success': true, 'data': local, 'fromCache': true};
    }

    return {
      'success': false,
      'message':
          'Animal não encontrado. Sem internet, só é possível abrir animais já salvos neste aparelho.',
    };
  }

  Future<List<dynamic>> getAnimals() async {
    try {
      final response = await ApiClient.get('/animals');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractList(decoded);
        await _cache.replaceAnimals(
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
        // Inclui animais locais ainda pendentes de sync.
        final local = await _cache.getAnimals();
        return _mergePreferLocalPending(list, local);
      }
    } catch (_) {
      // Offline: devolve cache.
    }

    return await _cache.getAnimals();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded['data'] is List) return decoded['data'] as List;
      if (decoded['animals'] is List) return decoded['animals'] as List;
    }
    return [];
  }

  /// Mantém itens PENDING do cache que ainda não existem no payload do servidor.
  List<dynamic> _mergePreferLocalPending(
    List<dynamic> remote,
    List<Map<String, dynamic>> local,
  ) {
    final remoteIds = <String>{};
    for (final item in remote) {
      if (item is Map) {
        final id = item['sisovId']?.toString() ?? item['id']?.toString();
        if (id != null) remoteIds.add(id);
      }
    }

    final merged = List<dynamic>.from(remote);
    for (final animal in local) {
      final id = animal['sisovId']?.toString();
      final syncStatus = animal['syncStatus']?.toString();
      if (id != null &&
          syncStatus == 'PENDING' &&
          id.startsWith('local_') &&
          !remoteIds.contains(id)) {
        merged.insert(0, animal);
      }
    }
    return merged;
  }

  Future<Map<String, dynamic>> transferAnimal({
    required String animalId,
    required String destinationPropertyId,
    required String destinationProducerId,
  }) async {
    return SyncService.instance.submitWrite(
      endpoint: '/animals/$animalId/transfer',
      payload: {
        'destinationPropertyId': destinationPropertyId,
        'destinationProducerId': destinationProducerId,
      },
      label: 'Transferência de animal',
    );
  }

  Future<Map<String, dynamic>> slaughterAnimal(String animalId) async {
    final result = await SyncService.instance.submitWrite(
      endpoint: '/animals/$animalId/slaughter',
      payload: {},
      label: 'Registro de abate',
    );
    if (result['success'] == true) {
      await _cache.updateAnimalStatus(animalId, 'SLAUGHTERED');
    }
    return result;
  }

  Future<Map<String, dynamic>> registerSlaughterBatch(
    SlaughterBatchRequest registration,
  ) async {
    final result = await SyncService.instance.submitWrite(
      endpoint: '/animals/slaughter-batch',
      payload: registration.toJson(),
      label: registration.items.length == 1
          ? 'Registro de abate'
          : 'Registro de abate em lote',
    );
    if (result['success'] == true) {
      final status = registration.mode == SlaughterMode.igSlaughterhouse
          ? 'SLAUGHTER_PENDING'
          : 'SLAUGHTERED';
      for (final item in registration.items) {
        await _cache.updateAnimalStatus(item.animalId, status);
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> registerManagementEvent(
    String animalId,
    Map<String, dynamic> eventData,
  ) async {
    return SyncService.instance.submitWrite(
      endpoint: '/animals/$animalId/management-events',
      payload: eventData,
      label: 'Evento de manejo',
    );
  }

  Future<List<ManagementEventModel>> getFullHistory(String animalId) async {
    try {
      final response = await ApiClient.get('/animals/$animalId/full-history');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final events = <ManagementEventModel>[];

        if (body is Map<String, dynamic>) {
          final list =
              body['managementEvents'] ?? body['events'] ?? body['data'];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                events.add(ManagementEventModel.fromJson(item));
              }
            }
          }
        } else if (body is List) {
          for (final item in body) {
            if (item is Map<String, dynamic>) {
              events.add(ManagementEventModel.fromJson(item));
            }
          }
        }

        return events;
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
