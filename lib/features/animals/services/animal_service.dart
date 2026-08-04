import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../models/management_event_model.dart';
import '../models/slaughter_registration_model.dart';

class AnimalService {

  Future<Map<String, dynamic>> createAnimal(
    Map<String, dynamic> animalData,
  ) async {
    return SyncService.instance.submitWrite(
      endpoint: '/animals',
      payload: animalData,
      label: 'Cadastro de animal',
    );
  }

  Future<Map<String, dynamic>> getAnimal(
    String identifier,
  ) async {
    try {
      final response = await ApiClient.get(
        '/animals/$identifier',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message':
              'Animal não encontrado no sistema.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erro de conexão: $e',
      };
    }
  }

  Future<List<dynamic>> getAnimals() async {
    try {
      final response =
          await ApiClient.get('/animals');

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is List) {
          return decoded;
        }

        if (decoded is Map) {
          if (decoded.containsKey('data')) {
            return decoded['data'];
          }

          if (decoded.containsKey(
            'animals',
          )) {
            return decoded['animals'];
          }
        }

        return [];
      } else {
        throw Exception(
          'Erro no servidor: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        'Erro ao buscar rebanho: $e',
      );

      throw Exception(
        'Falha de conexão ao buscar rebanho.',
      );
    }
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

  /// Regista o abate do animal
  /// e valida a IG
  /// (Indicação Geográfica)
  Future<Map<String, dynamic>>
  slaughterAnimal(
    String animalId,
  ) async {
    try {
      final response =
          await ApiClient.post(
            '/animals/$animalId/slaughter',
            {},
          );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      }

      final error =
          jsonDecode(response.body);

      return {
        'success': false,
        'message':
            error['message'] ??
            'Erro ao registar abate.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erro de conexão ao registar abate.',
      };
    }
  }

  /// Registra o abate do animal com requisitos técnicos da IG
  /// Valida conformidade com Caderno de Especificações Técnicas
  Future<Map<String, dynamic>> registerSlaughter(
    SlaughterRegistration registration,
  ) async {
    return SyncService.instance.submitWrite(
      endpoint:
          '/animals/${registration.animalId}/slaughter-with-requirements',
      payload: registration.toJson(),
      label: 'Registro de abate',
    );
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

  /// Procura o histórico completo
  /// (Eventos e Movimentações)
  Future<List<ManagementEventModel>>
  getFullHistory(
    String animalId,
  ) async {
    try {
      final response =
          await ApiClient.get(
            '/animals/$animalId/full-history',
          );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final events = <ManagementEventModel>[];

        if (body is Map<String, dynamic>) {
          if (body['managementEvents'] is List) {
            for (final item in body['managementEvents']) {
              if (item is Map<String, dynamic>) {
                events.add(ManagementEventModel.fromJson(item));
              }
            }
          } else if (body['events'] is List) {
            for (final item in body['events']) {
              if (item is Map<String, dynamic>) {
                events.add(ManagementEventModel.fromJson(item));
              }
            }
          } else if (body['data'] is List) {
            for (final item in body['data']) {
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