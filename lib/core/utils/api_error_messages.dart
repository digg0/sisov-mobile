import 'dart:convert';

/// Contexto da ação para mensagens mais específicas ao usuário.
enum ApiAction {
  login,
  register,
  createProperty,
  createAnimal,
  transfer,
  slaughter,
  management,
  generic,
}

/// Traduz respostas HTTP e falhas de rede em mensagens claras em português.
class ApiErrorMessages {
  ApiErrorMessages._();

  static String fromHttp({
    required int statusCode,
    String? body,
    ApiAction action = ApiAction.generic,
  }) {
    final decoded = _tryDecode(body);
    final serverText = extractServerText(decoded);
    final localized = serverText == null ? null : localizeKnown(serverText);

    if (localized != null && localized.isNotEmpty) {
      return localized;
    }

    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Confira o preenchimento e tente de novo.';
      case 401:
        if (action == ApiAction.login) {
          return 'E-mail ou senha incorretos. Verifique e tente novamente.';
        }
        return 'Sua sessão expirou. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para esta ação.';
      case 404:
        return _notFoundFor(action);
      case 409:
        if (action == ApiAction.register) {
          return 'Já existe um cadastro com este e-mail ou documento.';
        }
        return 'Este registro já existe ou conflita com outro.';
      case 422:
        final fields = _formatValidationDetails(decoded);
        if (fields != null) return fields;
        return 'Alguns campos estão inválidos. Revise e tente novamente.';
      case 429:
        return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente de novo.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'O servidor está temporariamente indisponível. Tente novamente em instantes.';
      default:
        if (statusCode >= 500) {
          return 'Falha no servidor. Tente novamente em instantes.';
        }
        return _fallbackFor(action);
    }
  }

  static String fromException(
    Object error, {
    ApiAction action = ApiAction.generic,
  }) {
    final text = error.toString().toLowerCase();

    if (text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('timeoutexception')) {
      return 'A conexão demorou demais. Verifique a internet e tente novamente.';
    }

    if (text.contains('socket') ||
        text.contains('failed host lookup') ||
        text.contains('network') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('clientexception') ||
        text.contains('xmlhttprequest')) {
      return 'Sem conexão com a internet. Verifique a rede e tente novamente.';
    }

    if (text.contains('formatexception') || text.contains('json')) {
      return 'A resposta do servidor veio incompleta. Tente novamente.';
    }

    return _fallbackFor(action);
  }

  /// Extrai texto útil do JSON da API (`error`, `message` ou detalhes Zod).
  static String? extractServerText(dynamic decoded) {
    if (decoded is! Map) return null;

    final error = decoded['error']?.toString().trim();
    if (error != null && error.isNotEmpty && error.toLowerCase() != 'null') {
      return error;
    }

    final message = decoded['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'null') {
      return message;
    }

    return null;
  }

  /// Converte mensagens conhecidas do backend (em inglês) para português.
  static String localizeKnown(String raw) {
    final normalized = raw.trim();
    final lower = normalized.toLowerCase();

    const exact = <String, String>{
      'invalid email or password.':
          'E-mail ou senha incorretos. Verifique e tente novamente.',
      'invalid email or password':
          'E-mail ou senha incorretos. Verifique e tente novamente.',
      'a producer with this document or email already exists.':
          'Já existe um cadastro com este e-mail ou documento.',
      'a producer with this document or email already exists':
          'Já existe um cadastro com este e-mail ou documento.',
      'no token provided. access denied.':
          'Sua sessão expirou. Faça login novamente.',
      'invalid or expired token.':
          'Sua sessão expirou. Faça login novamente.',
      'producer not found.':
          'Produtor não encontrado.',
      'producer not found':
          'Produtor não encontrado.',
      'animal not found.':
          'Animal não encontrado no sistema.',
      'animal not found':
          'Animal não encontrado no sistema.',
      'property not found.':
          'Propriedade não encontrada.',
      'property not found':
          'Propriedade não encontrada.',
      'validation failed':
          'Alguns campos estão inválidos. Revise e tente novamente.',
      'internal server error':
          'O servidor está temporariamente indisponível. Tente novamente em instantes.',
    };

    final mapped = exact[lower];
    if (mapped != null) return mapped;

    // Já está em português ou é mensagem genérica útil.
    if (_looksPortuguese(normalized)) return normalized;

    // Inglês genérico sem mapeamento: não exibir cru ao produtor.
    if (_looksEnglish(normalized)) {
      return 'Não foi possível concluir a operação. Tente novamente.';
    }

    return normalized;
  }

  static String? _formatValidationDetails(dynamic decoded) {
    if (decoded is! Map) return null;
    final details = decoded['details'];
    if (details is! Map) return null;

    final parts = <String>[];
    details.forEach((key, value) {
      final field = _fieldLabel(key.toString());
      if (value is List && value.isNotEmpty) {
        parts.add('$field: ${value.first}');
      } else if (value != null) {
        parts.add('$field: $value');
      }
    });

    if (parts.isEmpty) return null;
    if (parts.length == 1) {
      return 'Campo inválido — ${parts.first}. Confira e tente de novo.';
    }
    return 'Campos inválidos: ${parts.take(3).join('; ')}.';
  }

  static String _fieldLabel(String key) {
    const labels = {
      'email': 'e-mail',
      'password': 'senha',
      'name': 'nome',
      'document': 'CPF/CNPJ',
      'farmName': 'nome da propriedade',
      'city': 'cidade',
      'state': 'UF',
      'sisovId': 'identificador',
      'collarCode': 'coleira',
      'earTag': 'coleira',
    };
    return labels[key] ?? key;
  }

  static String _notFoundFor(ApiAction action) {
    switch (action) {
      case ApiAction.createAnimal:
      case ApiAction.transfer:
      case ApiAction.slaughter:
      case ApiAction.management:
        return 'Animal não encontrado no sistema.';
      case ApiAction.createProperty:
        return 'Propriedade não encontrada.';
      case ApiAction.login:
      case ApiAction.register:
        return 'Conta não encontrada. Verifique os dados ou cadastre-se.';
      case ApiAction.generic:
        return 'Registro não encontrado.';
    }
  }

  static String _fallbackFor(ApiAction action) {
    switch (action) {
      case ApiAction.login:
        return 'Não foi possível entrar. Tente novamente.';
      case ApiAction.register:
        return 'Não foi possível concluir o cadastro. Tente novamente.';
      case ApiAction.createProperty:
        return 'Não foi possível cadastrar a propriedade. Tente novamente.';
      case ApiAction.createAnimal:
        return 'Não foi possível cadastrar o animal. Tente novamente.';
      case ApiAction.transfer:
        return 'Não foi possível transferir o animal. Tente novamente.';
      case ApiAction.slaughter:
        return 'Não foi possível registrar o abate. Tente novamente.';
      case ApiAction.management:
        return 'Não foi possível registrar o manejo. Tente novamente.';
      case ApiAction.generic:
        return 'Não foi possível concluir a operação. Tente novamente.';
    }
  }

  static bool _looksPortuguese(String text) {
    final lower = text.toLowerCase();
    return lower.contains('ã') ||
        lower.contains('õ') ||
        lower.contains('ç') ||
        lower.contains('não') ||
        lower.contains('erro') ||
        lower.contains('inválid') ||
        lower.contains('senha') ||
        lower.contains('e-mail') ||
        lower.contains('email');
  }

  static bool _looksEnglish(String text) {
    final lower = text.toLowerCase();
    return lower.contains('invalid') ||
        lower.contains('failed') ||
        lower.contains('error') ||
        lower.contains('denied') ||
        lower.contains('unauthorized') ||
        lower.contains('not found') ||
        lower.contains('already exists') ||
        lower.contains('internal server');
  }

  static dynamic _tryDecode(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
