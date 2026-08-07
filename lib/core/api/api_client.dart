import 'dart:convert';

import 'package:http/http.dart' as http;

import '../security/secure_store.dart';

class ApiClient {
  static const String baseUrl = 'https://sisov-api.onrender.com';

  /// Chamado quando a API responde 401 (sessão expirada/inválida).
  static Future<void> Function()? onUnauthorized;

  static bool _handlingUnauthorized = false;

  static Future<Map<String, String>> _getHeaders({String? requestId}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token =
        await SecureStore.instance.read(key: SecureStore.jwtTokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (requestId != null) {
      headers['X-Client-Request-Id'] = requestId;
    }

    return headers;
  }

  static bool _isAuthPublicEndpoint(String endpoint) {
    return endpoint.startsWith('/auth/login') ||
        endpoint.startsWith('/auth/register');
  }

  static Future<void> _handleUnauthorized(
    String endpoint,
    http.Response response,
  ) async {
    if (response.statusCode != 401) return;
    // Login/register com senha errada também retornam 401 — não limpar sessão.
    if (_isAuthPublicEndpoint(endpoint)) return;
    if (_handlingUnauthorized) return;
    final callback = onUnauthorized;
    if (callback == null) return;
    _handlingUnauthorized = true;
    try {
      await callback();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? requestId,
  }) async {
    final headers = await _getHeaders(requestId: requestId);
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    await _handleUnauthorized(endpoint, response);
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(
      url,
      headers: headers,
    );
    await _handleUnauthorized(endpoint, response);
    return response;
  }
}
