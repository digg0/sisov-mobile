import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
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
    return SyncService.instance.submitWrite(
      endpoint: '/properties',
      payload: {
        'farmName': farmName,
        'city': city,
        'state': state,
      },
      label: 'Cadastro de propriedade',
    );
  }
}