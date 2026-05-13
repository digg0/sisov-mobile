import 'dart:convert';

import '../../../core/api/api_client.dart';

class AnimalService {

  Future<Map<String, dynamic>> createAnimal(
    Map<String, dynamic> animalData,
  ) async {
    try {
      final response = await ApiClient.post(
        '/animals',
        animalData,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error =
            jsonDecode(response.body);

        return {
          'success': false,
          'message':
              error['message'] ??
              'Erro ao cadastrar.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
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
    try {
      print("--- INICIANDO REQUEST DE TRANSFERÊNCIA ---");
      print("URL: /animals/$animalId/transfer");

      final response = await ApiClient.post(
        '/animals/$animalId/transfer',
        {
          'destinationPropertyId': destinationPropertyId,
          'destinationProducerId': destinationProducerId,
        },
      );

      print("STATUS CODE DA API: ${response.statusCode}");
      print("CORPO DA RESPOSTA: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erro na transferência.',
        };
      }
    } catch (e) {
      print("ERRO CRÍTICO NO SERVICE: $e");
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
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

  /// Procura o histórico completo
  /// (Eventos e Movimentações)
  Future<Map<String, dynamic>>
  getFullHistory(
    String animalId,
  ) async {
    try {
      final response =
          await ApiClient.get(
            '/animals/$animalId/full-history',
          );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      }

      return {
        'success': false,
        'message':
            'Erro ao carregar histórico.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erro de conexão ao carregar histórico.',
      };
    }
  }
}