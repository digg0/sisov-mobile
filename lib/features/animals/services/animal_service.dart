import 'dart:convert';
import '../../../core/api/api_client.dart';

class AnimalService {
  Future<Map<String, dynamic>> createAnimal(Map<String, dynamic> animalData) async {
    try {
      final response = await ApiClient.post('/animals', animalData);

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Erro ao cadastrar.'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  Future<Map<String, dynamic>> getAnimal(String identifier) async {
    try {
      final response = await ApiClient.get('/animals/$identifier');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Animal não encontrado no sistema.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}