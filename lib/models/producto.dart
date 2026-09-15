class Producto {
  int? id;
  String sku;
  String codigoBarras;
  String nombre;
  String? descripcion;
  
  // Relaciones (por ahora simples IDs)
  int? categoriaId;
  int? marcaId;
  int? proveedorId;
  int? ubicacionId;
  
  String? modelo;
  
  // Stock
  int stockActual;
  int stockMinimo;
  int stockMaximo;
  String unidadMedida;
  
  // Precios
  double precioCompra;
  double precioVenta;
  double? precioSugerido;
  double? margenGanancia;
  
  // Compra
  DateTime fechaCompra;
  String? numeroFactura;
  
  // Características
  double? peso;
  String? dimensiones;
  int? mesesGarantia;
  DateTime? fechaFinGarantia;
  
  // Estado
  bool estaActivo;
  bool estaDisponible;
  String estado; // 'en_stock', 'agotado', 'vendido', etc.
  
  // Auditoría
  DateTime fechaCreacion;
  DateTime fechaUltimaModificacion;
  String? nota;

  Producto({
    this.id,
    required this.sku,
    required this.codigoBarras,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    this.marcaId,
    this.proveedorId,
    this.ubicacionId,
    this.modelo,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockMaximo,
    this.unidadMedida = 'Unidad',
    required this.precioCompra,
    required this.precioVenta,
    this.precioSugerido,
    this.margenGanancia,
    required this.fechaCompra,
    this.numeroFactura,
    this.peso,
    this.dimensiones,
    this.mesesGarantia,
    this.fechaFinGarantia,
    this.estaActivo = true,
    this.estaDisponible = true,
    this.estado = 'en_stock',
    DateTime? fechaCreacion,
    DateTime? fechaUltimaModificacion,
    this.nota,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaUltimaModificacion = fechaUltimaModificacion ?? DateTime.now();

  // Getters calculados
  bool get tieneStockBajo => stockActual <= stockMinimo && stockActual > 0;
  bool get estaAgotado => stockActual <= 0;
  double get valorStock => stockActual * precioCompra;
  double get gananciaUnitaria => precioVenta - precioCompra;
  double get porcentajeGanancia {
    if (precioCompra <= 0) return 0;
    return ((precioVenta - precioCompra) / precioCompra) * 100;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'codigoBarras': codigoBarras,
    'nombre': nombre,
    'descripcion': descripcion,
    'categoriaId': categoriaId,
    'marcaId': marcaId,
    'proveedorId': proveedorId,
    'ubicacionId': ubicacionId,
    'modelo': modelo,
    'stockActual': stockActual,
    'stockMinimo': stockMinimo,
    'stockMaximo': stockMaximo,
    'unidadMedida': unidadMedida,
    'precioCompra': precioCompra,
    'precioVenta': precioVenta,
    'precioSugerido': precioSugerido,
    'margenGanancia': margenGanancia,
    'fechaCompra': fechaCompra.toIso8601String(),
    'numeroFactura': numeroFactura,
    'peso': peso,
    'dimensiones': dimensiones,
    'mesesGarantia': mesesGarantia,
    'fechaFinGarantia': fechaFinGarantia?.toIso8601String(),
    'estaActivo': estaActivo ? 1 : 0,
    'estaDisponible': estaDisponible ? 1 : 0,
    'estado': estado,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaUltimaModificacion': fechaUltimaModificacion.toIso8601String(),
    'nota': nota,
  };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id'],
    sku: map['sku'] ?? '',
    codigoBarras: map['codigoBarras'] ?? '',
    nombre: map['nombre'] ?? '',
    descripcion: map['descripcion'],
    categoriaId: map['categoriaId'],
    marcaId: map['marcaId'],
    proveedorId: map['proveedorId'],
    ubicacionId: map['ubicacionId'],
    modelo: map['modelo'],
    stockActual: map['stockActual'] ?? 0,
    stockMinimo: map['stockMinimo'] ?? 0,
    stockMaximo: map['stockMaximo'] ?? 0,
    unidadMedida: map['unidadMedida'] ?? 'Unidad',
    precioCompra: (map['precioCompra'] as num?)?.toDouble() ?? 0,
    precioVenta: (map['precioVenta'] as num?)?.toDouble() ?? 0,
    precioSugerido: (map['precioSugerido'] as num?)?.toDouble(),
    margenGanancia: (map['margenGanancia'] as num?)?.toDouble(),
    fechaCompra: map['fechaCompra'] != null 
        ? DateTime.parse(map['fechaCompra']) 
        : DateTime.now(),
    numeroFactura: map['numeroFactura'],
    peso: (map['peso'] as num?)?.toDouble(),
    dimensiones: map['dimensiones'],
    mesesGarantia: map['mesesGarantia'],
    fechaFinGarantia: map['fechaFinGarantia'] != null 
        ? DateTime.parse(map['fechaFinGarantia']) 
        : null,
    estaActivo: map['estaActivo'] == 1,
    estaDisponible: map['estaDisponible'] == 1,
    estado: map['estado'] ?? 'en_stock',
    fechaCreacion: map['fechaCreacion'] != null 
        ? DateTime.parse(map['fechaCreacion']) 
        : DateTime.now(),
    fechaUltimaModificacion: map['fechaUltimaModificacion'] != null 
        ? DateTime.parse(map['fechaUltimaModificacion']) 
        : DateTime.now(),
    nota: map['nota'],
  );

  Producto copyWith({
    int? id,
    String? sku,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    int? categoriaId,
    int? marcaId,
    int? proveedorId,
    int? ubicacionId,
    String? modelo,
    int? stockActual,
    int? stockMinimo,
    int? stockMaximo,
    String? unidadMedida,
    double? precioCompra,
    double? precioVenta,
    double? precioSugerido,
    double? margenGanancia,
    DateTime? fechaCompra,
    String? numeroFactura,
    double? peso,
    String? dimensiones,
    int? mesesGarantia,
    DateTime? fechaFinGarantia,
    bool? estaActivo,
    bool? estaDisponible,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaUltimaModificacion,
    String? nota,
  }) {
    return Producto(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      proveedorId: proveedorId ?? this.proveedorId,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      modelo: modelo ?? this.modelo,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      precioSugerido: precioSugerido ?? this.precioSugerido,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      numeroFactura: numeroFactura ?? this.numeroFactura,
      peso: peso ?? this.peso,
      dimensiones: dimensiones ?? this.dimensiones,
      mesesGarantia: mesesGarantia ?? this.mesesGarantia,
      fechaFinGarantia: fechaFinGarantia ?? this.fechaFinGarantia,
      estaActivo: estaActivo ?? this.estaActivo,
      estaDisponible: estaDisponible ?? this.estaDisponible,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaUltimaModificacion: DateTime.now(),
      nota: nota ?? this.nota,
    );
  }
}