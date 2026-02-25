import 'package:flutter/material.dart';
import 'package:sisov_mobile/screens/alimentacao_screen.dart';
import 'package:sisov_mobile/screens/detalhes_ovinos.dart';
import 'package:sisov_mobile/screens/home_screen.dart';
import 'package:sisov_mobile/screens/lista_rebanho.dart';
import 'package:sisov_mobile/screens/login_screen.dart';
import 'package:sisov_mobile/screens/procedimentos_screen.dart';
import 'package:sisov_mobile/screens/transacoes_screen.dart';
import 'package:sisov_mobile/screens/vacinacao_screen.dart'; // Import usando o nome do seu projeto

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
        '/lista_rebanho' : (context) => const ListaRebanhoScreen(),
        '/detalhes_ovino': (context) => const DetalhesOvinoScreen(),
        '/alimentacao': (context) => const AlimentacaoScreen(),
        '/vacinacao': (context) => const VacinacaoScreen(),
        '/procedimentos': (context) => const ProcedimentosScreen(),
        '/transacoes': (context) => const TransacoesScreen(),
      },
    );
  }
}