import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../models/property_model.dart';

class PropertyService {
  // Lista todas as fazendas do produtor logado
  Future<List<PropertyModel>> getProperties() async {
    try {
      final response = await ApiClient.get('/properties');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PropertyModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Cria uma nova fazenda
  Future<Map<String, dynamic>> createProperty({
    required String farmName,
    required String city,
    required String state,
  }) async {
    try {
      final response = await ApiClient.post('/properties', {
        'farmName': farmName,
        'city': city,
        'state': state,
      });

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? 'Erro ao processar'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão com o servidor'};
    }
  }
}