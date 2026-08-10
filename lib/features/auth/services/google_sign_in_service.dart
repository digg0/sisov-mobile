import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Resultado da autenticação feita pelo SDK do Google.
class GoogleIdentityResult {
  const GoogleIdentityResult._({this.idToken, this.errorMessage});

  const GoogleIdentityResult.success(String token)
    : this._(idToken: token);

  const GoogleIdentityResult.failure(String message)
    : this._(errorMessage: message);

  final String? idToken;
  final String? errorMessage;

  bool get isSuccess => idToken != null;
}

/// Encapsula o SDK Google e mantém sua inicialização única.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '606575197535-ebgklfv1hls80g5fccfs8ronpaihcd4h.apps.googleusercontent.com',
  );

  final GoogleSignIn _google = GoogleSignIn.instance;
  final StreamController<GoogleIdentityResult> _webResults =
      StreamController<GoogleIdentityResult>.broadcast();

  Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventsSubscription;

  bool get isConfigured => webClientId.trim().isNotEmpty;

  Stream<GoogleIdentityResult> get webResults => _webResults.stream;

  Future<void> initialize() {
    return _initialization ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    if (!isConfigured) return;

    await _google.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );

    if (kIsWeb) {
      _eventsSubscription = _google.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _webResults.add(_resultFromAccount(event.user));
          }
        },
        onError: (Object error) {
          _webResults.add(
            GoogleIdentityResult.failure(_messageForException(error)),
          );
        },
      );
    }
  }

  /// Abre o seletor de contas no Android.
  ///
  /// No Web, o GIS exige que a autenticação seja iniciada pelo botão oficial.
  Future<GoogleIdentityResult> authenticate() async {
    if (!isConfigured) {
      return const GoogleIdentityResult.failure(
        'Login Google ainda não está configurado neste aplicativo.',
      );
    }

    try {
      await initialize();
      if (!_google.supportsAuthenticate()) {
        return const GoogleIdentityResult.failure(
          'Use o botão oficial do Google para continuar.',
        );
      }
      final account = await _google.authenticate();
      return _resultFromAccount(account);
    } catch (error) {
      return GoogleIdentityResult.failure(_messageForException(error));
    }
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await initialize();
      await _google.signOut();
    } catch (_) {
      // A sessão SISOV deve ser encerrada mesmo se o SDK Google falhar.
    }
  }

  GoogleIdentityResult _resultFromAccount(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      return const GoogleIdentityResult.failure(
        'O Google não forneceu uma credencial válida. Tente novamente.',
      );
    }
    return GoogleIdentityResult.success(idToken);
  }

  String _messageForException(Object error) {
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return 'Login com Google cancelado.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Não foi possível abrir o login do Google. Tente novamente.';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return 'Login Google não configurado corretamente neste aplicativo.';
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'O serviço de login Google está indisponível no momento.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'A conta Google selecionada não corresponde à sessão atual.';
        case GoogleSignInExceptionCode.unknownError:
          return 'Não foi possível entrar com o Google. Tente novamente.';
      }
    }

    final text = error.toString().toLowerCase();
    if (text.contains('popup')) {
      return 'O navegador bloqueou a janela do Google. Libere pop-ups e tente novamente.';
    }
    if (text.contains('network') || text.contains('socket')) {
      return 'Sem conexão com o Google. Verifique a internet e tente novamente.';
    }
    return 'Não foi possível entrar com o Google. Tente novamente.';
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _eventsSubscription?.cancel();
    await _webResults.close();
  }
}
