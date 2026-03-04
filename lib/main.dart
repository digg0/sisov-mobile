import 'package:flutter/material.dart';
import 'package:sisov_mobile/screens/alimentacao_screen.dart';
import 'package:sisov_mobile/screens/detalhes_ovinos.dart';
import 'package:sisov_mobile/screens/home_screen.dart' hide Ovino;
import 'package:sisov_mobile/screens/lista_rebanho.dart';
import 'package:sisov_mobile/screens/login_screen.dart';
import 'package:sisov_mobile/screens/procedimentos_screen.dart';
import 'package:sisov_mobile/screens/transacoes_screen.dart';
import 'package:sisov_mobile/screens/vacinacao_screen.dart'; // Import usando o nome do seu projeto
import 'ovino_model.dart';

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
        useMaterial3: true,
      ),

      initialRoute: '/',

      // Rotas que NÃO precisam de dados externos (estáticas)
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/lista_rebanho' : (context) => const ListaRebanhoScreen(),
        '/alimentacao': (context) => const AlimentacaoScreen(),
        '/vacinacao': (context) => const VacinacaoScreen(),
        '/procedimentos': (context) => const ProcedimentosScreen(),
        '/transacoes': (context) => const TransacoesScreen(),
      },

      // Rota dinâmica para Detalhes (Extrai o objeto Ovino)
      onGenerateRoute: (settings) {
        if (settings.name == '/detalhes_ovino') {
          // Extrai o objeto Ovino passado via arguments
          final ovino = settings.arguments as Ovino;

          return MaterialPageRoute(
            builder: (context) => DetalhesOvinoScreen(ovino: ovino),
          );
        }
        return null;
      },
    );
  }
}