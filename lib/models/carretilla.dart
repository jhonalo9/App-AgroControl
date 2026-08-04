class Carretilla {
  final int? id;
  final int cargaId;
  final int numero;
  final double peso;

  Carretilla({
    this.id,
    required this.cargaId,
    required this.numero,
    required this.peso,
  });

  factory Carretilla.fromMap(Map<String, dynamic> map) {
    return Carretilla(
      id: map['id'] as int?,
      cargaId: map['carga_id'] as int,
      numero: map['numero'] as int,
      peso: (map['peso'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carga_id': cargaId,
      'numero': numero,
      'peso': peso,
    };
  }
}
