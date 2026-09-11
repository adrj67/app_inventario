class Proveedor {
  int? id;
  String nombre;
  String? cuit;
  String? telefono;
  String? email;
  String? direccion;
  String? contacto;
  String? nota;
  bool activo;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Proveedor({
    this.id,
    required this.nombre,
    this.cuit,
    this.telefono,
    this.email,
    this.direccion,
    this.contacto,
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
    'contacto': contacto,
    'nota': nota,
    'activo': activo ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['id'],
    nombre: map['nombre'],
    cuit: map['cuit'],
    telefono: map['telefono'],
    email: map['email'],
    direccion: map['direccion'],
    contacto: map['contacto'],
    nota: map['nota'],
    activo: map['activo'] == 1,
    fechaCreacion: DateTime.parse(map['fechaCreacion']),
    fechaModificacion: DateTime.parse(map['fechaModificacion']),
  );

  Proveedor copyWith({String? nombre, bool? activo}) => Proveedor(
    id: id,
    nombre: nombre ?? this.nombre,
    cuit: cuit,
    telefono: telefono,
    email: email,
    direccion: direccion,
    contacto: contacto,
    nota: nota,
    activo: activo ?? this.activo,
    fechaCreacion: fechaCreacion,
    fechaModificacion: DateTime.now(),
  );
}