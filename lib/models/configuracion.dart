class Configuracion {
  int? id;
  String nombreEmpresa;
  String? cuit;
  String? direccion;
  String? telefono;
  String? email;
  String? sitioWeb;
  String? condicionIva;
  String? logoPath;
  String? observaciones;
  DateTime fechaModificacion;

  Configuracion({
    this.id,
    required this.nombreEmpresa,
    this.cuit,
    this.direccion,
    this.telefono,
    this.email,
    this.sitioWeb,
    this.condicionIva,
    this.logoPath,
    this.observaciones,
    DateTime? fechaModificacion,
  }) : fechaModificacion = fechaModificacion ?? DateTime.now();

  // Configuración por defecto (la primera vez)
  factory Configuracion.vacia() => Configuracion(
    nombreEmpresa: 'Mi Empresa',
    condicionIva: 'Responsable Inscripto',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombreEmpresa': nombreEmpresa,
    'cuit': cuit,
    'direccion': direccion,
    'telefono': telefono,
    'email': email,
    'sitioWeb': sitioWeb,
    'condicionIva': condicionIva,
    'logoPath': logoPath,
    'observaciones': observaciones,
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Configuracion.fromMap(Map<String, dynamic> map) => Configuracion(
    id: map['id'],
    nombreEmpresa: map['nombreEmpresa'] ?? 'Mi Empresa',
    cuit: map['cuit'],
    direccion: map['direccion'],
    telefono: map['telefono'],
    email: map['email'],
    sitioWeb: map['sitioWeb'],
    condicionIva: map['condicionIva'],
    logoPath: map['logoPath'],
    observaciones: map['observaciones'],
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Configuracion copyWith({
    int? id,
    String? nombreEmpresa,
    String? cuit,
    String? direccion,
    String? telefono,
    String? email,
    String? sitioWeb,
    String? condicionIva,
    String? logoPath,
    String? observaciones,
    DateTime? fechaModificacion,
  }) {
    return Configuracion(
      id: id ?? this.id,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      cuit: cuit ?? this.cuit,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      condicionIva: condicionIva ?? this.condicionIva,
      logoPath: logoPath ?? this.logoPath,
      observaciones: observaciones ?? this.observaciones,
      fechaModificacion: DateTime.now(),
    );
  }
}