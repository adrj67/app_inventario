class PresupuestoItem {
  int? id;
  int presupuestoId;
  int productoId;
  String nombreProducto; // Snapshot por si luego se elimina el producto
  String sku; // Snapshot
  int cantidad;
  double precioUnitario;
  double subtotal;
  String? nota;

  PresupuestoItem({
    this.id,
    required this.presupuestoId,
    required this.productoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.precioUnitario,
    this.nota,
  }) : subtotal = cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
    'id': id,
    'presupuestoId': presupuestoId,
    'productoId': productoId,
    'nombreProducto': nombreProducto,
    'sku': sku,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
    'subtotal': subtotal,
    'nota': nota,
  };

  factory PresupuestoItem.fromMap(Map<String, dynamic> map) => PresupuestoItem(
    id: map['id'],
    presupuestoId: map['presupuestoId'] ?? 0,
    productoId: map['productoId'] ?? 0,
    nombreProducto: map['nombreProducto'] ?? '',
    sku: map['sku'] ?? '',
    cantidad: map['cantidad'] ?? 0,
    precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0,
    nota: map['nota'],
  );

  PresupuestoItem copyWith({
    int? id,
    int? presupuestoId,
    int? productoId,
    String? nombreProducto,
    String? sku,
    int? cantidad,
    double? precioUnitario,
    String? nota,
  }) {
    return PresupuestoItem(
      id: id ?? this.id,
      presupuestoId: presupuestoId ?? this.presupuestoId,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      sku: sku ?? this.sku,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      nota: nota ?? this.nota,
    );
  }
}