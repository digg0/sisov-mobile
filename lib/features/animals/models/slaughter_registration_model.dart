enum SlaughterMode {
  standard('STANDARD', 'Abate padrão'),
  igOwn('IG_OWN', 'IG por conta própria'),
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
  final String? frigorificoCode;
  final String? additionalNotes;
  final String? proofOfAge;
  final String? carcassColor;
  final String? fatColor;
  final String? meatTexture;
  final bool? hasBoletimEmbarque;
  final bool? hasGTA;
  final bool? hasHTA;
  final bool confirmWelfare;
  final bool confirmSanity;
  final bool? geographicOriginConfirmed;
  final bool? preSlaughterFastingConfirmed;

  const SlaughterCommonData({
    required this.slaughterDate,
    required this.slaughterLocation,
    this.frigorificoCode,
    this.additionalNotes,
    this.proofOfAge,
    this.carcassColor,
    this.fatColor,
    this.meatTexture,
    this.hasBoletimEmbarque,
    this.hasGTA,
    this.hasHTA,
    this.confirmWelfare = false,
    this.confirmSanity = false,
    this.geographicOriginConfirmed,
    this.preSlaughterFastingConfirmed,
  });

  Map<String, dynamic> toJson() => {
    'slaughterDate': slaughterDate.toIso8601String(),
    'slaughterLocation': slaughterLocation,
    if (frigorificoCode?.isNotEmpty == true) 'frigorificoCode': frigorificoCode,
    if (additionalNotes?.isNotEmpty == true) 'additionalNotes': additionalNotes,
    if (proofOfAge != null) 'proofOfAge': proofOfAge,
    if (carcassColor != null) 'carcassColor': carcassColor,
    if (fatColor != null) 'fatColor': fatColor,
    if (meatTexture != null) 'meatTexture': meatTexture,
    if (hasBoletimEmbarque != null) 'hasBoletimEmbarque': hasBoletimEmbarque,
    if (hasGTA != null) 'hasGTA': hasGTA,
    if (hasHTA != null) 'hasHTA': hasHTA,
    if (proofOfAge != null) 'confirmWelfare': confirmWelfare,
    if (proofOfAge != null) 'confirmSanity': confirmSanity,
    if (geographicOriginConfirmed != null)
      'geographicOriginConfirmed': geographicOriginConfirmed,
    if (preSlaughterFastingConfirmed != null)
      'preSlaughterFastingConfirmed': preSlaughterFastingConfirmed,
  };
}

class SlaughterBatchItem {
  const SlaughterBatchItem({
    required this.animalId,
    this.carcassWeight,
    this.carcassYield,
  });

  final String animalId;
  final double? carcassWeight;
  final double? carcassYield;

  Map<String, dynamic> toJson() => {
    'animalId': animalId,
    if (carcassWeight != null) 'carcassWeight': carcassWeight,
    if (carcassYield != null) 'carcassYield': carcassYield,
  };
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
    if (mode == SlaughterMode.igOwn) {
      if (items.any(
        (item) => item.carcassWeight == null || item.carcassWeight! <= 0,
      )) {
        return 'Informe um peso de carcaça válido para cada animal.';
      }
      if (items.any(
        (item) =>
            item.carcassYield == null ||
            item.carcassYield! < 42 ||
            item.carcassYield! > 100,
      )) {
        return 'O rendimento de cada carcaça deve ficar entre 42% e 100%.';
      }
    }
    return null;
  }
}
