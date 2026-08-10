import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/db/database_init.dart';
import 'core/session/session_service.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/animals/views/animal_search_screen.dart';
import 'features/animals/views/select_property_animal_screen.dart';
import 'features/auth/views/auth_gate.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/home_screen.dart';
import 'features/auth/services/google_sign_in_service.dart';
import 'features/properties/views/properties_create_screen.dart';
import 'features/properties/views/properties_list_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chrome/Web: sqflite precisa do factory WASM antes de abrir o banco.
  await initDatabaseFactory();

  try {
    await GoogleSignInService.instance.initialize();
  } catch (error) {
    // Login por e-mail continua disponível se a configuração Google falhar.
    debugPrint('GoogleSignIn.initialize falhou: $error');
  }

  // Sessão inválida (401): limpa dados locais e força novo login.
  ApiClient.onUnauthorized = () async {
    await SessionService.instance.logoutAndWipe();
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  };

  try {
    await SyncService.instance.init();
  } catch (e, st) {
    // Não bloquear a UI (tela branca) se o storage local falhar no web.
    debugPrint('SyncService.init falhou: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SISOV — Rastreabilidade Ovina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: appNavigatorKey,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/properties': (context) => const PropertiesListScreen(),
        '/properties/add': (context) => const PropertyCreateScreen(),
        '/select-property': (context) => const SelectPropertyForAnimalScreen(),
        '/search-animal': (context) =>
            const AnimalSearchScreen(isTransferMode: false),
      },
    );
  }
}
