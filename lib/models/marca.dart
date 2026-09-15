class Marca {
  int? id;
  String nombre;
  String? descripcion;
  bool activa;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Marca({
    this.id,
    required this.nombre,
    this.descripcion,
    this.activa = true,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'activa': activa ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Marca.fromMap(Map<String, dynamic> map) => Marca(
    id: map['id'],
    nombre: map['nombre'] ?? '',
    descripcion: map['descripcion'],
    activa: map['activa'] == 1,
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Marca copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Marca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }
}