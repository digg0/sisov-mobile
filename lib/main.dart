import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/animals/views/animal_search_screen.dart';
import 'features/animals/views/select_property_animal_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/home_screen.dart';
import 'features/properties/views/properties_create_screen.dart';
import 'features/properties/views/properties_list_screen.dart'; // Importe a home aqui

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SISOV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      initialRoute: '/login',
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
