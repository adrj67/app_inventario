class Ubicacion {
  int? id;
  String deposito;
  String? pasillo;
  String? estante;
  String? nivel;
  String? codigoQR;
  String? descripcion;
  bool activo;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Ubicacion({
    this.id,
    required this.deposito,
    this.pasillo,
    this.estante,
    this.nivel,
    this.codigoQR,
    this.descripcion,
    this.activo = true,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  // Getter para mostrar ubicación completa
  String get nombreCompleto {
    final parts = <String>[deposito];
    if (pasillo != null && pasillo!.isNotEmpty) parts.add('Pasillo $pasillo');
    if (estante != null && estante!.isNotEmpty) parts.add('Estante $estante');
    if (nivel != null && nivel!.isNotEmpty) parts.add('Nivel $nivel');
    return parts.join(' - ');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'deposito': deposito,
    'pasillo': pasillo,
    'estante': estante,
    'nivel': nivel,
    'codigoQR': codigoQR,
    'descripcion': descripcion,
    'activo': activo ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Ubicacion.fromMap(Map<String, dynamic> map) => Ubicacion(
    id: map['id'],
    deposito: map['deposito'] ?? '',
    pasillo: map['pasillo'],
    estante: map['estante'],
    nivel: map['nivel'],
    codigoQR: map['codigoQR'],
    descripcion: map['descripcion'],
    activo: map['activo'] == 1,
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Ubicacion copyWith({
    int? id,
    String? deposito,
    String? pasillo,
    String? estante,
    String? nivel,
    String? codigoQR,
    String? descripcion,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Ubicacion(
      id: id ?? this.id,
      deposito: deposito ?? this.deposito,
      pasillo: pasillo ?? this.pasillo,
      estante: estante ?? this.estante,
      nivel: nivel ?? this.nivel,
      codigoQR: codigoQR ?? this.codigoQR,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }
}