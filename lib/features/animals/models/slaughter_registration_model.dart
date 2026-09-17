enum SlaughterMode {
  standard('STANDARD', 'Abate padrão sem IG'),
  igSlaughterhouse('IG_SLAUGHTERHOUSE', 'IG pelo abatedouro');

  const SlaughterMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory SlaughterMode.fromApi(String value) => values.firstWhere(
    (mode) => mode.apiValue == value,
    orElse: () => SlaughterMode.standard,
  );
}

class SlaughterAnimal {
  const SlaughterAnimal({
    required this.id,
    required this.tagId,
    required this.birthDate,
  });

  final String id;
  final String tagId;
  final DateTime birthDate;

  factory SlaughterAnimal.fromMap(Map<String, dynamic> map) {
    final rawDate = map['birthDate']?.toString();
    return SlaughterAnimal(
      id:
          map['sisovId']?.toString() ??
          map['id']?.toString() ??
          map['_id']?.toString() ??
          '',
      tagId: map['tagId']?.toString() ?? 'Sem coleira',
      birthDate: DateTime.tryParse(rawDate ?? '') ?? DateTime.now(),
    );
  }
}

class SlaughterCommonData {
  final DateTime slaughterDate;
  final String slaughterLocation;
  final Map<String, dynamic>? location;
  final String? frigorificoCode;
  final String? additionalNotes;

  const SlaughterCommonData({
    required this.slaughterDate,
    required this.slaughterLocation,
    this.location,
    this.frigorificoCode,
    this.additionalNotes,
  });

  Map<String, dynamic> toJson() => {
    'slaughterDate': slaughterDate.toIso8601String(),
    'slaughterLocation': slaughterLocation,
    if (location != null) 'location': location,
    if (frigorificoCode?.isNotEmpty == true) 'frigorificoCode': frigorificoCode,
    if (additionalNotes?.isNotEmpty == true) 'additionalNotes': additionalNotes,
  };
}

class SlaughterBatchItem {
  const SlaughterBatchItem({required this.animalId});

  final String animalId;

  Map<String, dynamic> toJson() => {'animalId': animalId};
}

class SlaughterBatchRequest {
  const SlaughterBatchRequest({
    required this.mode,
    required this.commonData,
    required this.items,
  });

  final SlaughterMode mode;
  final SlaughterCommonData commonData;
  final List<SlaughterBatchItem> items;

  Map<String, dynamic> toJson() => {
    'mode': mode.apiValue,
    ...commonData.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  String? validate() {
    if (items.isEmpty) return 'Selecione pelo menos um animal.';
    if (items.any((item) => item.animalId.isEmpty)) {
      return 'Há um animal sem identificador válido.';
    }
    if (commonData.slaughterLocation.trim().isEmpty) {
      return 'Informe o local do abate.';
    }
    if (commonData.location == null) {
      return 'Capture a localização atual do abate.';
    }
    if (mode == SlaughterMode.igSlaughterhouse &&
        (commonData.frigorificoCode?.trim().isEmpty ?? true)) {
      return 'Informe o código SIF, SIE ou SIM do abatedouro.';
    }
    return null;
  }
}
