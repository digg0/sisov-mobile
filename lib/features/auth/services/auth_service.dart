import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/db/local_cache.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/utils/api_error_messages.dart';

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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map && responseData['token'] != null) {
          await _finishAuthentication(responseData);

          return {
            'success': true,
            'message': 'Login realizado com sucesso. Bem-vindo!',
          };
        }
      }

      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
          action: ApiAction.login,
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(
          e,
          action: ApiAction.login,
        ),
      };
    }
  }

  /// Troca um ID token verificado pelo Google por uma sessão JWT do SISOV.
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await ApiClient.post('/auth/google', {
        'idToken': idToken,
      });
      final decoded = _decodeMap(response.body);

      if (response.statusCode == 200 && decoded?['token'] != null) {
        await _finishAuthentication(decoded!);
        return {
          'success': true,
          'message': 'Login com Google realizado com sucesso.',
        };
      }

      if (response.statusCode == 428 &&
          decoded?['code'] == 'PROFILE_COMPLETION_REQUIRED' &&
          decoded?['onboardingToken'] is String) {
        return {
          'success': false,
          'requiresProfileCompletion': true,
          'onboardingToken': decoded!['onboardingToken'],
          'profile': decoded['profile'],
          'message':
              'Informe seu CPF ou CNPJ para concluir o cadastro no SISOV.',
        };
      }

      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
          action: ApiAction.googleLogin,
        ),
      };
    } catch (error) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(
          error,
          action: ApiAction.googleLogin,
        ),
      };
    }
  }

  /// Conclui o primeiro acesso Google com o documento obrigatório do produtor.
  Future<Map<String, dynamic>> completeGoogleProfile({
    required String onboardingToken,
    required String document,
  }) async {
    try {
      final response = await ApiClient.post('/auth/google/complete', {
        'onboardingToken': onboardingToken,
        'document': document.replaceAll(RegExp(r'\D'), ''),
      });
      final decoded = _decodeMap(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          decoded?['token'] != null) {
        await _finishAuthentication(decoded!);
        return {
          'success': true,
          'message': 'Cadastro concluído. Bem-vindo ao SISOV!',
        };
      }

      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
          action: ApiAction.googleLogin,
        ),
      };
    } catch (error) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(
          error,
          action: ApiAction.googleLogin,
        ),
      };
    }
  }

  Future<void> _finishAuthentication(Map<dynamic, dynamic> responseData) async {
    final token = responseData['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Token de sessão ausente');
    }

    final previousUserId = await getCurrentUserId();
    await _storage.write(key: SecureStore.jwtTokenKey, value: token);

    Map<String, dynamic>? profile;
    try {
      final profileResponse = await ApiClient.get('/auth/profile');
      if (profileResponse.statusCode == 200) {
        profile = _decodeMap(profileResponse.body);
      }
    } catch (_) {
      // Usa o produtor devolvido no login se o perfil agregado falhar.
    }

    final producer = responseData['producer'];
    if (profile == null && producer is Map) {
      profile = Map<String, dynamic>.from(producer);
    }

    if (profile != null) {
      final newUserId = profile['id']?.toString();
      if (previousUserId != null &&
          newUserId != null &&
          previousUserId != newUserId) {
        await LocalCache.instance.clearAll();
      }
      await _saveProfile(profile);
    }
  }

  Map<String, dynamic>? _decodeMap(String body) {
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
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

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              'Cadastro realizado com sucesso! Agora faça login para continuar.',
        };
      }

      return {
        'success': false,
        'message': ApiErrorMessages.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
          action: ApiAction.register,
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiErrorMessages.fromException(
          e,
          action: ApiAction.register,
        ),
      };
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
