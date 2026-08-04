class Carga {
  final int? id;
  final int comercianteId;
  final double precioKg;
   final double descuentoKg; 
  final String fecha; // formato ISO8601
  final bool finalizada;
  final bool sincronizada; // para cuando se implemente sync con servidor

  Carga({
    this.id,
    required this.comercianteId,
    required this.precioKg,
    this.descuentoKg = 0,
    required this.fecha,
    this.finalizada = false,
    this.sincronizada = false,
  });

  factory Carga.fromMap(Map<String, dynamic> map) {
    return Carga(
      id: map['id'] as int?,
      comercianteId: map['comerciante_id'] as int,
      precioKg: (map['precio_kg'] as num).toDouble(),
      descuentoKg: (map['descuento_kg'] as num?)?.toDouble() ?? 0,
      fecha: map['fecha'] as String,
      finalizada: (map['finalizada'] as int) == 1,
      sincronizada: (map['sincronizada'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comerciante_id': comercianteId,
      'descuento_kg': descuentoKg,
      'precio_kg': precioKg,
      'fecha': fecha,
      'finalizada': finalizada ? 1 : 0,
      'sincronizada': sincronizada ? 1 : 0,
    };
  }

  Carga copyWith({bool? finalizada, bool? sincronizada}) {
    return Carga(
      id: id,
      comercianteId: comercianteId,
      precioKg: precioKg,
      descuentoKg: descuentoKg,
      fecha: fecha,
      finalizada: finalizada ?? this.finalizada,
      sincronizada: sincronizada ?? this.sincronizada,
    );
  }
}

/// Modelo auxiliar para mostrar el historial ya con los totales calculados
/// (join entre cargas + comerciantes + suma de carretillas).
class CargaResumen {
  final Carga carga;
  final String comercianteNombre;
  final double pesoBrutoTotal;
  final double pesoTotal;
  final int totalCarretillas;

  CargaResumen({
    required this.carga,
    required this.comercianteNombre,
    required this.pesoBrutoTotal,
    required this.pesoTotal,
    required this.totalCarretillas,
  });

  double get totalPagar => pesoTotal * carga.precioKg;
}
