class Ovino {
  final String id;
  final String tagId;
  final String sexo;
  final String raca;
  final String dataNasc;
  final String municipio;
  final String estado;
  final double pesoNasc;
  final String? pai;
  final String? mae;
  final int sincronizado; // 0 = Pendente, 1 = Sincronizado

  Ovino({
    required this.id, required this.tagId, required this.sexo,
    required this.raca, required this.dataNasc, required this.municipio,
    required this.estado, required this.pesoNasc, this.pai, this.mae,
    this.sincronizado = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'tagId': tagId, 'sexo': sexo, 'raca': raca,
      'dataNasc': dataNasc, 'municipio': municipio, 'estado': estado,
      'pesoNasc': pesoNasc, 'pai': pai, 'mae': mae,
      'sincronizado': sincronizado,
    };
  }

  factory Ovino.fromMap(Map<String, dynamic> map) {
    return Ovino(
      id: map['id'], tagId: map['tagId'], sexo: map['sexo'],
      raca: map['raca'] ?? '', dataNasc: map['dataNasc'] ?? '',
      municipio: map['municipio'] ?? '', estado: map['estado'] ?? '',
      pesoNasc: (map['pesoNasc'] as num?)?.toDouble() ?? 0.0,
      pai: map['pai'], mae: map['mae'],
      sincronizado: map['sincronizado'] ?? 0,
    );
  }
}