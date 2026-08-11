import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/db/local_cache.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/api_error_messages.dart';
import '../models/property_model.dart';

class PropertyService {
  final _cache = LocalCache.instance;

  Future<List<PropertyModel>> getProperties() async {
    try {
      final response = await ApiClient.get('/properties');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : <dynamic>[];
        final maps = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        await _cache.replaceProperties(maps);

        final local = await _cache.getProperties();
        return _mergeProperties(maps, local);
      }
    } catch (_) {
      // Offline: cache local.
    }

    final local = await _cache.getProperties();
    return local
        .map(
          (json) => PropertyModel(
            id: json['id']?.toString() ?? '',
            farmName: json['farmName']?.toString() ?? '',
            city: json['city']?.toString() ?? '',
            state: json['state']?.toString() ?? '',
          ),
        )
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  List<PropertyModel> _mergeProperties(
    List<Map<String, dynamic>> remote,
    List<Map<String, dynamic>> local,
  ) {
    final remoteIds = remote.map((e) => e['id']?.toString()).toSet();
    final result = remote.map((json) => PropertyModel.fromJson(json)).toList();

    for (final item in local) {
      final id = item['id']?.toString() ?? '';
      final syncStatus = item['syncStatus']?.toString();
      if (id.startsWith('local_') &&
          syncStatus == 'PENDING' &&
          !remoteIds.contains(id)) {
        result.insert(
          0,
          PropertyModel(
            id: id,
            farmName: item['farmName']?.toString() ?? '',
            city: item['city']?.toString() ?? '',
            state: item['state']?.toString() ?? '',
          ),
        );
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> createProperty({
    required String farmName,
    required String city,
    required String state,
  }) async {
    final localId = SyncService.newLocalId();
    await _cache.upsertProperty({
      'id': localId,
      'farmName': farmName,
      'city': city,
      'state': state,
      'syncStatus': 'PENDING',
    });

    final result = await SyncService.instance.submitWrite(
      endpoint: '/properties',
      payload: {'farmName': farmName, 'city': city, 'state': state},
      label: 'Cadastro de propriedade',
      entityType: 'property',
      localEntityId: localId,
    );

    if (result['success'] != true) {
      await _cache.deleteProperty(localId);
    }

    return {...result, 'localEntityId': localId};
  }

  Future<Map<String, dynamic>> updatePropertyName({
    required PropertyModel property,
    required String farmName,
  }) async {
    if (property.id.startsWith('local_')) {
      return {
        'success': false,
        'message':
            'Aguarde a sincronização da propriedade antes de editar o nome.',
      };
    }

    try {
      final response = await ApiClient.patch('/properties/${property.id}', {
        'farmName': farmName,
      });
      if (response.statusCode == 200) {
        await _cache.upsertProperty({
          'id': property.id,
          'farmName': farmName,
          'city': property.city,
          'state': property.state,
          'syncStatus': 'SYNCED',
        });
        return {'success': true};
      }
      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
        ),
      };
    } catch (error) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(error),
      };
    }
  }

  Future<Map<String, dynamic>> deleteProperty(PropertyModel property) async {
    if (property.id.startsWith('local_')) {
      return {
        'success': false,
        'message': 'Aguarde a sincronização da propriedade antes de excluí-la.',
      };
    }

    try {
      final response = await ApiClient.delete('/properties/${property.id}');
      if (response.statusCode == 204) {
        await _cache.deleteProperty(property.id);
        return {'success': true};
      }
      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
        ),
      };
    } catch (error) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(error),
      };
    }
  }
}
