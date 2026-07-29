class SlaughterRegistration {
  final String animalId; // Usado apenas na URL, não enviado no corpo
  final DateTime slaughterDate;
  final String slaughterLocation;
  final double carcassWeight;
  final String proofOfAge; // 'RASTREABILIDADE' ou 'DENTES'
  final String carcassColor; // 'VERMELHA_ROSADA'
  final String fatColor; // 'BRANCA'
  final String meatTexture; // 'FINA'
  final bool hasBoletimEmbarque; // Possui Boletim de Embarque
  final bool hasGTA; // Possui Guia de Trânsito Animal
  final bool hasHTA; // Possui Higiene e Tecnologia de Abate
  final bool confirmWelfare;
  final bool confirmSanity;
  final bool
      geographicOriginConfirmed; // Criado em Tauá ou min. 3 meses na região (Art. 6º, §1º)
  final bool
      preSlaughterFastingConfirmed; // Dieta hídrica 12h + sólida 16h (Art. 8º)
  final double carcassYield; // Rendimento da carcaça (%)
  final String additionalNotes;
  final String frigorificoCode; // Código do frigorífico (SIF/SIE/SIM)

  SlaughterRegistration({
    required this.animalId,
    required this.slaughterDate,
    required this.slaughterLocation,
    required this.carcassWeight,
    required this.proofOfAge,
    required this.carcassColor,
    required this.fatColor,
    required this.meatTexture,
    required this.hasBoletimEmbarque,
    required this.hasGTA,
    required this.hasHTA,
    required this.confirmWelfare,
    required this.confirmSanity,
    required this.geographicOriginConfirmed,
    required this.preSlaughterFastingConfirmed,
    required this.carcassYield,
    required this.additionalNotes,
    required this.frigorificoCode,
  });

  Map<String, dynamic> toJson() => {
    'proofOfAge': proofOfAge,
    'carcassColor': carcassColor,
    'fatColor': fatColor,
    'meatTexture': meatTexture,
    'carcassWeight': carcassWeight,
    'carcassYield': carcassYield,
    'hasBoletimEmbarque': hasBoletimEmbarque,
    'hasGTA': hasGTA,
    'hasHTA': hasHTA,
    'slaughterDate': slaughterDate.toIso8601String(),
    'slaughterLocation': slaughterLocation,
    'frigorificoCode': frigorificoCode,
    'confirmWelfare': confirmWelfare,
    'confirmSanity': confirmSanity,
    'geographicOriginConfirmed': geographicOriginConfirmed,
    'preSlaughterFastingConfirmed': preSlaughterFastingConfirmed,
    if (additionalNotes.isNotEmpty) 'additionalNotes': additionalNotes,
  };

  factory SlaughterRegistration.fromJson(Map<String, dynamic> json) =>
      SlaughterRegistration(
        animalId: json['animalId'] as String? ?? '',
        slaughterDate: DateTime.parse(json['slaughterDate'] as String),
        slaughterLocation: json['slaughterLocation'] as String,
        carcassWeight: (json['carcassWeight'] as num).toDouble(),
        proofOfAge: json['proofOfAge'] as String,
        carcassColor: json['carcassColor'] as String,
        fatColor: json['fatColor'] as String,
        meatTexture: json['meatTexture'] as String,
        hasBoletimEmbarque: json['hasBoletimEmbarque'] as bool? ?? false,
        hasGTA: json['hasGTA'] as bool? ?? false,
        hasHTA: json['hasHTA'] as bool? ?? false,
        confirmWelfare: json['confirmWelfare'] as bool? ?? false,
        confirmSanity: json['confirmSanity'] as bool? ?? false,
        geographicOriginConfirmed:
            json['geographicOriginConfirmed'] as bool? ?? false,
        preSlaughterFastingConfirmed:
            json['preSlaughterFastingConfirmed'] as bool? ?? false,
        carcassYield: (json['carcassYield'] as num).toDouble(),
        additionalNotes: json['additionalNotes'] as String? ?? '',
        frigorificoCode: json['frigorificoCode'] as String,
      );
}
