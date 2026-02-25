import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlimentacaoScreen extends StatelessWidget {
  const AlimentacaoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alimentação')),
      body: const Center(child: Text('Tela de Alimentação\n(Aguardando atualizações futuras)', textAlign: TextAlign.center)),
    );
  }
}