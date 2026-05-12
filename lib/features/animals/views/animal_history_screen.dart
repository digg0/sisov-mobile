import 'package:flutter/material.dart';

class AnimalHistoryScreen extends StatelessWidget {
  final List<dynamic> events; // ManagementEvents vindo da API

  const AnimalHistoryScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Histórico de Rastreabilidade")),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            leading: const Icon(Icons.history_edu, color: Color(0xFF0F8F82)),
            title: Text(event['eventType']), // Ex: VACCINATION, SLAUGHTER
            subtitle: Text(event['description'] ?? 'Sem observações'),
            trailing: Text(event['createdAt'].toString().split('T')[0]),
          );
        },
      ),
    );
  }
}