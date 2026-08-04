class Comerciante {
  final int? id;
  final String nombre;
  final String? telefono;

  Comerciante({this.id, required this.nombre, this.telefono});

  factory Comerciante.fromMap(Map<String, dynamic> map) {
    return Comerciante(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
    };
  }

  Comerciante copyWith({int? id, String? nombre, String? telefono}) {
    return Comerciante(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
    );
  }
}
