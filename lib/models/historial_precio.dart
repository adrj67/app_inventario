class HistorialPrecio {
  int? id;
  int productoId;
  double precioCompra;
  double precioVenta;
  double margenGanancia;
  double porcentajeGanancia;
  DateTime fecha;
  String? nota;

  HistorialPrecio({
    this.id,
    required this.productoId,
    required this.precioCompra,
    required this.precioVenta,
    required this.margenGanancia,
    required this.porcentajeGanancia,
    DateTime? fecha,
    this.nota,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'precioCompra': precioCompra,
    'precioVenta': precioVenta,
    'margenGanancia': margenGanancia,
    'porcentajeGanancia': porcentajeGanancia,
    'fecha': fecha.toIso8601String(),
    'nota': nota,
  };

  factory HistorialPrecio.fromMap(Map<String, dynamic> map) => HistorialPrecio(
    id: map['id'],
    productoId: map['productoId'] ?? 0,
    precioCompra: (map['precioCompra'] as num?)?.toDouble() ?? 0,
    precioVenta: (map['precioVenta'] as num?)?.toDouble() ?? 0,
    margenGanancia: (map['margenGanancia'] as num?)?.toDouble() ?? 0,
    porcentajeGanancia: (map['porcentajeGanancia'] as num?)?.toDouble() ?? 0,
    fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
    nota: map['nota'],
  );
}