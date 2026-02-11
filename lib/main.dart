import 'package:flutter/material.dart';
import 'package:sisov_mobile/screens/home_screen.dart';
import 'package:sisov_mobile/screens/login_screen.dart'; // Import usando o nome do seu projeto

void main() {
  runApp(const SisovApp());
}

class SisovApp extends StatelessWidget {
  const SisovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sisov Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Estilo mais moderno
      ),

      // Rota inicial
      initialRoute: '/',

      // Definindo o mapa de rotas
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}