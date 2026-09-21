class Presupuesto {
  int? id;
  String numero; // Ej: "PRES-2026-0001"
  int? clienteId;
  DateTime fecha;
  DateTime fechaVencimiento;
  double subtotal;
  double iva;
  double total;
  double porcentajeIva;
  String estado; // 'pendiente', 'aprobado', 'rechazado', 'vencido'
  String? nota;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Presupuesto({
    this.id,
    required this.numero,
    this.clienteId,
    DateTime? fecha,
    DateTime? fechaVencimiento,
    this.subtotal = 0,
    this.iva = 0,
    this.total = 0,
    this.porcentajeIva = 21,
    this.estado = 'pendiente',
    this.nota,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fecha = fecha ?? DateTime.now(),
        fechaVencimiento =
            fechaVencimiento ?? DateTime.now().add(const Duration(days: 7)),
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  // Getter: ¿está vencido?
  bool get estaVencido {
    if (estado == 'aprobado' || estado == 'rechazado') return false;
    return DateTime.now().isAfter(fechaVencimiento);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'numero': numero,
    'clienteId': clienteId,
    'fecha': fecha.toIso8601String(),
    'fechaVencimiento': fechaVencimiento.toIso8601String(),
    'subtotal': subtotal,
    'iva': iva,
    'total': total,
    'porcentajeIva': porcentajeIva,
    'estado': estado,
    'nota': nota,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaModificacion': fechaModificacion.toIso8601String(),
  };

  factory Presupuesto.fromMap(Map<String, dynamic> map) => Presupuesto(
    id: map['id'],
    numero: map['numero'] ?? '',
    clienteId: map['clienteId'],
    fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
    fechaVencimiento: map['fechaVencimiento'] != null
        ? DateTime.parse(map['fechaVencimiento'])
        : DateTime.now().add(const Duration(days: 7)),
    subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    iva: (map['iva'] as num?)?.toDouble() ?? 0,
    total: (map['total'] as num?)?.toDouble() ?? 0,
    porcentajeIva: (map['porcentajeIva'] as num?)?.toDouble() ?? 21,
    estado: map['estado'] ?? 'pendiente',
    nota: map['nota'],
    fechaCreacion: map['fechaCreacion'] != null
        ? DateTime.parse(map['fechaCreacion'])
        : DateTime.now(),
    fechaModificacion: map['fechaModificacion'] != null
        ? DateTime.parse(map['fechaModificacion'])
        : DateTime.now(),
  );

  Presupuesto copyWith({
    int? id,
    String? numero,
    int? clienteId,
    DateTime? fecha,
    DateTime? fechaVencimiento,
    double? subtotal,
    double? iva,
    double? total,
    double? porcentajeIva,
    String? estado,
    String? nota,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Presupuesto(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      fecha: fecha ?? this.fecha,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      subtotal: subtotal ?? this.subtotal,
      iva: iva ?? this.iva,
      total: total ?? this.total,
      porcentajeIva: porcentajeIva ?? this.porcentajeIva,
      estado: estado ?? this.estado,
      nota: nota ?? this.nota,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }
}