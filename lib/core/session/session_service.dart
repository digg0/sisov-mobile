import '../../features/animals/services/animal_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/google_sign_in_service.dart';
import '../../features/properties/services/property_service.dart';
import '../db/local_cache.dart';
import '../sync/sync_service.dart';

/// Orquestra sessão offline-first: aquecimento de cache e limpeza segura no logout.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final _auth = AuthService();
  final _animals = AnimalService();
  final _properties = PropertyService();

  /// Baixa e persiste perfil + propriedades + animais enquanto houver internet.
  /// Offline: não falha — o cache anterior permanece.
  Future<void> warmCache() async {
    await Future.wait([
      _auth.getProfile(),
      _properties.getProperties(),
      _animals.getAnimals(),
    ]);
  }

  /// Encerra sessão e apaga dados locais do produtor (evita vazamento entre contas).
  Future<void> logoutAndWipe() async {
    SyncService.instance.pause();
    await LocalCache.instance.clearAll();
    await _auth.clearSession();
    await GoogleSignInService.instance.signOut();
    SyncService.instance.resume();
    await SyncService.instance.refreshPendingCount();
  }
}
