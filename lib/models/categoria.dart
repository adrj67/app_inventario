class Categoria {
  int? id;
  String nombre;
  String? descripcion;
  int? categoriaPadreId; // Para subcategorías
  bool activa;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion,
    this.categoriaPadreId,
    this.activa = true,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'categoriaPadreId': categoriaPadreId,
    'activa': activa ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
    id: map['id'],
    nombre: map['nombre'] ?? '',
    descripcion: map['descripcion'],
    categoriaPadreId: map['categoriaPadreId'],
    activa: map['activa'] == 1,
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Categoria copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? categoriaPadreId,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaPadreId: categoriaPadreId ?? this.categoriaPadreId,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }
}