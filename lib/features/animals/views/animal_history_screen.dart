import 'package:flutter/material.dart';

import '../models/management_event_model.dart';

class AnimalHistoryScreen extends StatelessWidget {
  final List<ManagementEventModel> events;

  const AnimalHistoryScreen({super.key, required this.events});

  IconData _iconForType(String type) {
    switch (type) {
      case 'VACCINATION':
        return Icons.medical_services;
      case 'VET_TREATMENT':
        return Icons.healing;
      case 'WEIGHT_MEASUREMENT':
        return Icons.monitor_weight;
      case 'NUTRITIONAL_FEEDING':
        return Icons.restaurant;
      case 'REPRODUCTION_COVERAGE':
        return Icons.pregnant_woman;
      case 'SANITARY_DOCUMENT':
        return Icons.description;
      case 'SLAUGHTER_FINALIZATION':
        return Icons.set_meal;
      default:
        return Icons.history_edu;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Rastreabilidade')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            leading: Icon(_iconForType(event.eventType), color: const Color(0xFF0F8F82)),
            title: Text(event.label),
            subtitle: Text(event.subtitle.isNotEmpty ? event.subtitle : 'Sem observações'),
            trailing: Text(event.formattedDate),
          );
        },
      ),
    );
  }
}