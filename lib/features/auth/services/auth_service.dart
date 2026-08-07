import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/db/local_cache.dart';
import '../../../core/security/secure_store.dart';

class AuthService {
  final _storage = SecureStore.instance;

  Future<bool> hasSession() async {
    final token = await _storage.read(key: SecureStore.jwtTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final raw = await _storage.read(key: SecureStore.profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> _saveProfile(Map<String, dynamic> profile) async {
    await _storage.write(
      key: SecureStore.profileKey,
      value: jsonEncode(profile),
    );
    final userId = profile['id']?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: SecureStore.userIdKey, value: userId);
    }
  }

  Future<String?> getCurrentUserId() async {
    return _storage.read(key: SecureStore.userIdKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          final previousUserId = await getCurrentUserId();

          await _storage.write(
            key: SecureStore.jwtTokenKey,
            value: responseData['token'],
          );

          // Se mudou de conta, limpa o snapshot offline do usuário anterior.
          Map<String, dynamic>? profile;
          try {
            final profileResponse = await ApiClient.get('/auth/profile');
            if (profileResponse.statusCode == 200) {
              final decoded = jsonDecode(profileResponse.body);
              if (decoded is Map) {
                profile = Map<String, dynamic>.from(decoded);
                await _saveProfile(profile);
              }
            }
          } catch (_) {}

          final newUserId = profile?['id']?.toString();
          if (previousUserId != null &&
              newUserId != null &&
              previousUserId != newUserId) {
            await LocalCache.instance.clearAll();
          }

          return {'success': true, 'message': 'Login realizado com sucesso'};
        }
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Erro ao realizar login',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão.'};
    }
  }

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
        return {
          'success': true,
          'message':
              'Cadastro realizado com sucesso! Faça login para continuar.',
        };
      } else if (response.statusCode == 409) {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Já existe um produtor com este documento ou e-mail.',
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Erro de validação dos campos.',
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Muitas tentativas. Tente novamente em 15 minutos.',
        };
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Erro ao realizar cadastro.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão.'};
    }
  }

  /// Remove token e perfil do armazenamento seguro.
  Future<void> clearSession() async {
    await _storage.delete(key: SecureStore.jwtTokenKey);
    await _storage.delete(key: SecureStore.profileKey);
    await _storage.delete(key: SecureStore.userIdKey);
  }

  @Deprecated('Use SessionService.instance.logoutAndWipe()')
  Future<void> logout() async {
    await clearSession();
  }

  /// Busca perfil na API e persiste; offline devolve o último snapshot.
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await ApiClient.get('/auth/profile');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final profile = Map<String, dynamic>.from(decoded);
          await _saveProfile(profile);
          return profile;
        }
      }
      if (response.statusCode == 401) {
        return null;
      }
    } catch (_) {
      // Offline ou rede instável.
    }

    return getCachedProfile();
  }
}
