import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_vacinacao_screen.dart'; // Importe o formulário que criamos antes

class VacinacaoScreen extends StatelessWidget {
  const VacinacaoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacinação')),
      body: const Center(child: Text('Tela de Vacinação\n(Aguardando atualizações futuras)', textAlign: TextAlign.center)),
    );
  }
}