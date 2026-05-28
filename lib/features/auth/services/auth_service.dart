import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Método de Login (você já tem este)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {'email': email, 'password': password});
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          await _storage.write(key: 'jwt_token', value: responseData['token']);
          return {'success': true, 'message': 'Login realizado com sucesso'};
        }
      }
      return {'success': false, 'message': responseData['message'] ?? 'Erro ao realizar login'};
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão.'};
    }
  }

  // Método de Cadastro
  Future<Map<String, dynamic>> register(
    String name,
    String document,
    String email,
    String password,
  ) async {
    try {
      final response = await ApiClient.post(
        '/auth/register',
        {
          'name': name,
          'document': document,
          'email': email,
          'password': password,
        },
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Cadastro realizado com sucesso! Faça login para continuar.'};
      } else if (response.statusCode == 409) {
        return {'success': false, 'message': responseData['message'] ?? 'Já existe um produtor com este documento ou e-mail.'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': responseData['message'] ?? 'Erro de validação dos campos.'};
      } else if (response.statusCode == 429) {
        return {'success': false, 'message': 'Muitas tentativas. Tente novamente em 15 minutos.'};
      }
      return {'success': false, 'message': responseData['message'] ?? 'Erro ao realizar cadastro.'};
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão.'};
    }
  }

  // --- ADICIONE ESTE MÉTODO PARA O LOGOUT ---
  Future<void> logout() async {
    // Apaga o token do armazenamento seguro do celular
    await _storage.delete(key: 'jwt_token');
  }

  // --- ADICIONE ESTE MÉTODO PARA PEGAR OS DADOS DO PERFIL NA HOME ---
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await ApiClient.get('/auth/profile');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}