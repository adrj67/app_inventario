class Cliente {
  int? id;
  String nombre;
  String? cuit;
  String? telefono;
  String? email;
  String? direccion;
  String? localidad;
  String? nota;
  bool activo;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Cliente({
    this.id,
    required this.nombre,
    this.cuit,
    this.telefono,
    this.email,
    this.direccion,
    this.localidad,
    this.nota,
    this.activo = true,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'cuit': cuit,
    'telefono': telefono,
    'email': email,
    'direccion': direccion,
    'localidad': localidad,
    'nota': nota,
    'activo': activo ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
    id: map['id'],
    nombre: map['nombre'] ?? '',
    cuit: map['cuit'],
    telefono: map['telefono'],
    email: map['email'],
    direccion: map['direccion'],
    localidad: map['localidad'],
    nota: map['nota'],
    activo: map['activo'] == 1,
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Cliente copyWith({
    int? id,
    String? nombre,
    String? cuit,
    String? telefono,
    String? email,
    String? direccion,
    String? localidad,
    String? nota,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cuit: cuit ?? this.cuit,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      localidad: localidad ?? this.localidad,
      nota: nota ?? this.nota,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }
}