import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento seguro compartilhado (Keystore / Keychain).
///
/// iOS: restringe o JWT ao aparelho (não migra via backup iCloud).
/// Android: usa o Keystore AES-GCM padrão do plugin v10+.
class SecureStore {
  SecureStore._();

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(),
  );

  static const jwtTokenKey = 'jwt_token';
  static const profileKey = 'cached_profile';
  static const userIdKey = 'current_user_id';
}
