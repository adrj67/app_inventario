class Movimiento {
  int? id;
  int productoId;
  String tipo; // 'entrada', 'salida', 'ajuste'
  int cantidad; // Positivo siempre (el tipo define la dirección)
  double precioUnitario;
  String? motivo; // 'compra', 'venta', 'devolucion', 'perdida', 'inventario', 'otro'
  String? nota;
  String? numeroFactura;
  DateTime fecha;
  String? usuario;
  DateTime fechaCreacion;

  Movimiento({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.precioUnitario = 0,
    this.motivo,
    this.nota,
    this.numeroFactura,
    DateTime? fecha,
    this.usuario,
    DateTime? fechaCreacion,
  })  : fecha = fecha ?? DateTime.now(),
        fechaCreacion = fechaCreacion ?? DateTime.now();

  // Getter: cantidad con signo
  int get cantidadConSigno {
    if (tipo == 'salida') return -cantidad;
    return cantidad;
  }

  // Getter: total del movimiento
  double get total => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'tipo': tipo,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
    'motivo': motivo,
    'nota': nota,
    'numeroFactura': numeroFactura,
    'fecha': fecha.toIso8601String(),
    'usuario': usuario,
    'fechaCreacion': fechaCreacion.toIso8601String(),
  };

  factory Movimiento.fromMap(Map<String, dynamic> map) => Movimiento(
    id: map['id'],
    productoId: map['productoId'] ?? 0,
    tipo: map['tipo'] ?? 'entrada',
    cantidad: map['cantidad'] ?? 0,
    precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0,
    motivo: map['motivo'],
    nota: map['nota'],
    numeroFactura: map['numeroFactura'],
    fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
    usuario: map['usuario'],
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
  );

  Movimiento copyWith({
    int? id,
    int? productoId,
    String? tipo,
    int? cantidad,
    double? precioUnitario,
    String? motivo,
    String? nota,
    String? numeroFactura,
    DateTime? fecha,
    String? usuario,
    DateTime? fechaCreacion,
  }) {
    return Movimiento(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      motivo: motivo ?? this.motivo,
      nota: nota ?? this.nota,
      numeroFactura: numeroFactura ?? this.numeroFactura,
      fecha: fecha ?? this.fecha,
      usuario: usuario ?? this.usuario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}