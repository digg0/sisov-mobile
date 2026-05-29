class ManagementEventModel {
  final String? id;
  final String? animalId;
  final String? responsibleId;
  final String eventType;
  final String? description;
  final String? eventLocation;
  final DateTime? occurredAt;

  ManagementEventModel({
    this.id,
    this.animalId,
    this.responsibleId,
    required this.eventType,
    this.description,
    this.eventLocation,
    this.occurredAt,
  });

  factory ManagementEventModel.fromJson(Map<String, dynamic> json) {
    DateTime? occurredAt;
    if (json['occurredAt'] != null) {
      try {
        occurredAt = DateTime.parse(json['occurredAt'].toString());
      } catch (_) {
        occurredAt = null;
      }
    }

    return ManagementEventModel(
      id: json['id']?.toString(),
      animalId: json['animalId']?.toString(),
      responsibleId: json['responsibleId']?.toString(),
      eventType: json['eventType']?.toString() ?? 'UNKNOWN',
      description: json['description']?.toString(),
      eventLocation: json['eventLocation']?.toString(),
      occurredAt: occurredAt,
    );
  }

  String get formattedDate {
    if (occurredAt == null) return 'Data não informada';
    return '${occurredAt!.day.toString().padLeft(2, '0')}/${occurredAt!.month.toString().padLeft(2, '0')}/${occurredAt!.year}';
  }

  String get label {
    switch (eventType) {
      case 'VACCINATION':
        return 'Vacinação';
      case 'VET_TREATMENT':
        return 'Tratamento Veterinário';
      case 'WEIGHT_MEASUREMENT':
        return 'Medição de Peso';
      case 'NUTRITIONAL_FEEDING':
        return 'Alimentação';
      case 'REPRODUCTION_COVERAGE':
        return 'Cobertura Reprodutiva';
      case 'SANITARY_DOCUMENT':
        return 'Documento Sanitário';
      case 'SLAUGHTER_FINALIZATION':
        return 'Finalização de Abate';
      default:
        return eventType.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
    }
  }

  String get subtitle {
    final parts = <String>[];
    if (description != null && description!.isNotEmpty) parts.add(description!);
    if (eventLocation != null && eventLocation!.isNotEmpty) parts.add(eventLocation!);
    return parts.join(' • ');
  }
}
