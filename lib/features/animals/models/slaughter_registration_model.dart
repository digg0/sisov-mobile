class SlaughterRegistration {
  final String animalId;
  final DateTime slaughterDate;
  final String slaughterLocation;
  final double carcassWeight;
  final String animalAgeProof; // 'TRACEABILITY' ou 'TEETH'
  final String carcassColor; // 'PINK_RED' para vermelha rosada
  final String fatColor; // 'WHITE' para branca
  final String meatTexture; // 'FINE' para fina
  final String bulletinNumber; // Boletim de Embarque
  final String gtaNumber; // Guia de Trânsito Animal
  final String htaNumber; // HTA (Higiene e Tecnologia de Abate)
  final bool animalWelfareConfirmed;
  final bool sanitaryConditionConfirmed;
  final double carcassRendimento; // Rendimento da carcaça (%)
  final String observations;
  final String slaughterhouseCode; // Código do frigorífico

  SlaughterRegistration({
    required this.animalId,
    required this.slaughterDate,
    required this.slaughterLocation,
    required this.carcassWeight,
    required this.animalAgeProof,
    required this.carcassColor,
    required this.fatColor,
    required this.meatTexture,
    required this.bulletinNumber,
    required this.gtaNumber,
    required this.htaNumber,
    required this.animalWelfareConfirmed,
    required this.sanitaryConditionConfirmed,
    required this.carcassRendimento,
    required this.observations,
    required this.slaughterhouseCode,
  });

  Map<String, dynamic> toJson() => {
    'animalId': animalId,
    'slaughterDate': slaughterDate.toIso8601String(),
    'slaughterLocation': slaughterLocation,
    'carcassWeight': carcassWeight,
    'animalAgeProof': animalAgeProof,
    'carcassColor': carcassColor,
    'fatColor': fatColor,
    'meatTexture': meatTexture,
    'bulletinNumber': bulletinNumber,
    'gtaNumber': gtaNumber,
    'htaNumber': htaNumber,
    'animalWelfareConfirmed': animalWelfareConfirmed,
    'sanitaryConditionConfirmed': sanitaryConditionConfirmed,
    'carcassRendimento': carcassRendimento,
    'observations': observations,
    'slaughterhouseCode': slaughterhouseCode,
  };

  factory SlaughterRegistration.fromJson(Map<String, dynamic> json) =>
      SlaughterRegistration(
        animalId: json['animalId'] as String,
        slaughterDate: DateTime.parse(json['slaughterDate'] as String),
        slaughterLocation: json['slaughterLocation'] as String,
        carcassWeight: (json['carcassWeight'] as num).toDouble(),
        animalAgeProof: json['animalAgeProof'] as String,
        carcassColor: json['carcassColor'] as String,
        fatColor: json['fatColor'] as String,
        meatTexture: json['meatTexture'] as String,
        bulletinNumber: json['bulletinNumber'] as String,
        gtaNumber: json['gtaNumber'] as String,
        htaNumber: json['htaNumber'] as String,
        animalWelfareConfirmed: json['animalWelfareConfirmed'] as bool,
        sanitaryConditionConfirmed: json['sanitaryConditionConfirmed'] as bool,
        carcassRendimento: (json['carcassRendimento'] as num).toDouble(),
        observations: json['observations'] as String,
        slaughterhouseCode: json['slaughterhouseCode'] as String,
      );
}
