import 'package:flutter/material.dart';


class TransacoesScreen extends StatelessWidget {
  const TransacoesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: const Center(child: Text('Tela de Transações e Financeiro\n(Aguardando atualizações futuras)', textAlign: TextAlign.center)),
    );
  }
}