import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// URL Base da sua API Node.js
  /// IMPORTANTE:
  /// - Use 'http://10.0.2.2:3333' se estiver rodando no Emulador Android.
  /// - Use o IP local da sua rede (ex: 'http://192.168.1.15:3333') se testar no celular físico.
  static const String baseUrl = 'https://sisov-api.onrender.com';

  static const _storage = FlutterSecureStorage();

  /// Constrói os cabeçalhos padrão para todas as requisições.
  /// Já verifica automaticamente se existe um JWT salvo e o injeta na chamada.
  static Future<Map<String, String>> _getHeaders({String? requestId}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Identificador único da requisição (idempotência): permite ao backend
    // ignorar reenvios duplicados vindos da fila de sincronização offline.
    if (requestId != null) {
      headers['X-Client-Request-Id'] = requestId;
    }

    return headers;
  }

  /// Método genérico para requisições do tipo POST (ex: Login, Registrar Ovino)
  ///
  /// [requestId] é opcional e, quando informado, é enviado no header
  /// `X-Client-Request-Id` para garantir idempotência no reenvio offline.
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? requestId,
  }) async {
    final headers = await _getHeaders(requestId: requestId);
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /// Método genérico para requisições do tipo GET (ex: Listar Propriedades, Buscar Perfil)
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.get(
      url,
      headers: headers,
    );
  }
}