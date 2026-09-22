import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../database/presupuesto_repository.dart';
import '../../../database/cliente_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/presupuesto.dart';
import '../../../models/presupuesto_item.dart';
import '../../../models/cliente.dart';
import '../../../models/producto.dart';
import '../../../database/configuracion_repository.dart';
import '../../../services/presupuesto_pdf_service.dart';

class PresupuestoForm extends StatefulWidget {
  final Presupuesto? presupuesto;

  const PresupuestoForm({super.key, this.presupuesto});

  @override
  State<PresupuestoForm> createState() => _PresupuestoFormState();
}

class _PresupuestoFormState extends State<PresupuestoForm> {
  final _formKey = GlobalKey<FormState>();
  final PresupuestoRepository _repository = PresupuestoRepository();
  final ClienteRepository _clienteRepository = ClienteRepository();
  final ProductoRepository _productoRepository = ProductoRepository();

  // ==================== CONTROLLERS ====================
  final TextEditingController _notaController = TextEditingController();

  // ==================== STATE ====================
  String _numero = '';
  DateTime _fecha = DateTime.now();
  DateTime _fechaVencimiento = DateTime.now().add(const Duration(days: 7));
  int? _clienteId;
  String _estado = 'pendiente';
  double _porcentajeIva = 21;
  final List<PresupuestoItem> _items = [];

  // Caches
  List<Cliente> _clientes = [];
  List<Producto> _productos = [];
  bool _cargandoDatos = true;
  bool _guardando = false;

  bool get _esEdicion => widget.presupuesto != null;

  // ==================== CÁLCULOS ====================
  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  double get _iva => _subtotal * (_porcentajeIva / 100);

  double get _total => _subtotal + _iva;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _clienteRepository.getAll();
      final productos = await _productoRepository.getAll();

      if (_esEdicion) {
        // Cargar datos del presupuesto existente
        final p = widget.presupuesto!;
        final items = await _repository.getItems(p.id!);

        setState(() {
          _numero = p.numero;
          _fecha = p.fecha;
          _fechaVencimiento = p.fechaVencimiento;
          _clienteId = p.clienteId;
          _estado = p.estado;
          _porcentajeIva = p.porcentajeIva;
          _notaController.text = p.nota ?? '';
          _items.clear();
          _items.addAll(items);
        });
      } else {
        // Nuevo presupuesto: generar número
        final numero = await _repository.generarNumero();
        setState(() => _numero = numero);
      }

      setState(() {
        _clientes = clientes;
        _productos = productos;
        _cargandoDatos = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _cargandoDatos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_esEdicion ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
          backgroundColor: Colors.deepOrange.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          // 🔥 Botón Generar PDF
          if (!_cargandoDatos && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Generar PDF del presupuesto',
                child: OutlinedButton.icon(
                  onPressed: _generarPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text(
                    'PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          // Número del presupuesto
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _numero,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  _buildSeccionDatosGenerales(),
                  const SizedBox(height: 16),
                  _buildSeccionProductos(),
                  const SizedBox(height: 16),
                  _buildSeccionTotales(),
                  const SizedBox(height: 16),
                  _buildSeccionNotas(),
                  const SizedBox(height: 24),
                  _buildBotones(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SECCIONES ====================

  Widget _buildSeccionDatosGenerales() {
    return _buildCard(
      titulo: 'Datos Generales',
      icono: Icons.info_outline,
      children: [
        Row(
          children: [
            // Cliente
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: _clienteId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Cliente *',
                  prefixIcon: Icon(Icons.person, color: Colors.deepOrange.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Sin cliente'),
                  ),
                  ..._clientes.map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          c.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _clienteId = v),
              ),
            ),
            const SizedBox(width: 16),

            // Estado
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.flag, color: Colors.deepOrange.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'aprobado', child: Text('Aprobado')),
                  DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                ],
                onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _seleccionarFecha(esVencimiento: false),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.deepOrange.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _seleccionarFecha(esVencimiento: true),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Vencimiento (auto: +7 días)',
                    prefixIcon: Icon(Icons.event, color: Colors.deepOrange.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_fechaVencimiento)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: _porcentajeIva,
                decoration: InputDecoration(
                  labelText: 'IVA',
                  prefixIcon: Icon(Icons.percent, color: Colors.deepOrange.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0% (Exento)')),
                  DropdownMenuItem(value: 10.5, child: Text('10.5%')),
                  DropdownMenuItem(value: 21.0, child: Text('21%')),
                  DropdownMenuItem(value: 27.0, child: Text('27%')),
                ],
                onChanged: (v) => setState(() => _porcentajeIva = v ?? 21),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionProductos() {
    return _buildCard(
      titulo: 'Productos',
      icono: Icons.shopping_cart,
      trailing: TextButton.icon(
        onPressed: _abrirSelectorProductos,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar Producto'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.deepOrange.shade700,
        ),
      ),
      children: [
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No hay productos agregados',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hacé clic en "Agregar Producto" para comenzar',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          )
        else
          Column(
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemProducto(index, item);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildItemProducto(int index, PresupuestoItem item) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Número
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nombre y SKU
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'SKU: ${item.sku}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Cantidad
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: item.cantidad.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Cant.',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) {
                final n = int.tryParse(v) ?? 1;
                if (n > 0) {
                  setState(() {
                    _items[index] = item.copyWith(cantidad: n);
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Precio unitario
          SizedBox(
            width: 130,
            child: TextFormField(
              initialValue: item.precioUnitario.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) {
                final p = double.tryParse(v) ?? 0;
                setState(() {
                  _items[index] = item.copyWith(precioUnitario: p);
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Subtotal
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  currencyFormat.format(item.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Quitar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _quitarProducto(index),
            tooltip: 'Quitar',
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTotales() {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

    return _buildCard(
      titulo: 'Totales',
      icono: Icons.calculate,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 350,
              child: Column(
                children: [
                  _buildFilaTotal(
                    'Subtotal:',
                    currencyFormat.format(_subtotal),
                    Colors.grey.shade800,
                  ),
                  const SizedBox(height: 8),
                  _buildFilaTotal(
                    'IVA (${_porcentajeIva.toStringAsFixed(1)}%):',
                    currencyFormat.format(_iva),
                    Colors.grey.shade800,
                  ),
                  const Divider(thickness: 2, height: 24),
                  _buildFilaTotal(
                    'TOTAL:',
                    currencyFormat.format(_total),
                    Colors.green,
                    grande: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilaTotal(String label, String valor, Color color, {bool grande = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: grande ? 18 : 14,
            fontWeight: grande ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: grande ? 22 : 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionNotas() {
    return _buildCard(
      titulo: 'Notas / Observaciones',
      icono: Icons.note,
      children: [
        TextFormField(
          controller: _notaController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ej: Forma de pago, plazos de entrega, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _guardando || _items.isEmpty ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _guardando
                  ? 'Guardando...'
                  : (_esEdicion ? 'Actualizar Presupuesto' : 'Guardar Presupuesto'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.deepOrange.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ==================== ACCIONES ====================

  Future<void> _seleccionarFecha({required bool esVencimiento}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esVencimiento ? _fechaVencimiento : _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'AR'),
    );
    if (fecha != null) {
      setState(() {
        if (esVencimiento) {
          _fechaVencimiento = fecha;
        } else {
          _fecha = fecha;
          // Recalcular vencimiento automáticamente
          _fechaVencimiento = fecha.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _abrirSelectorProductos() async {
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos cargados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final producto = await showDialog<Producto>(
      context: context,
      builder: (context) => _SelectorProductoDialog(
        productos: _productos,
        productosYaAgregados: _items.map((i) => i.productoId).toList(),
      ),
    );

    if (producto != null) {
      setState(() {
        _items.add(PresupuestoItem(
          presupuestoId: widget.presupuesto?.id ?? 0,
          productoId: producto.id!,
          nombreProducto: producto.nombre,
          sku: producto.sku,
          cantidad: 1,
          precioUnitario: producto.precioVenta,
        ));
      });
    }
  }

  void _quitarProducto(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _generarPdf() async {
    // Validación: debe estar guardado (tener ID)
    if (widget.presupuesto?.id == null && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardá el presupuesto primero para generar el PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregá al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Cargar la configuración de la empresa
      final config = await ConfiguracionRepository().get();

      // Buscar el cliente
      final cliente = _clienteId != null
          ? _clientes.where((c) => c.id == _clienteId).firstOrNull
          : null;

      // Construir el presupuesto temporal (con los valores actuales del form)
      final presupuesto = Presupuesto(
        id: widget.presupuesto?.id,
        numero: _numero,
        clienteId: _clienteId,
        fecha: _fecha,
        fechaVencimiento: _fechaVencimiento,
        subtotal: _subtotal,
        iva: _iva,
        total: _total,
        porcentajeIva: _porcentajeIva,
        estado: _estado,
        nota: _notaController.text.trim().isEmpty ? null : _notaController.text.trim(),
        fechaCreacion: widget.presupuesto?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await PresupuestoPdfService.generarPdfPresupuesto(
        presupuesto: presupuesto,
        items: _items,
        cliente: cliente,
        config: config,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregá al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final presupuesto = Presupuesto(
        id: widget.presupuesto?.id,
        numero: _numero,
        clienteId: _clienteId,
        fecha: _fecha,
        fechaVencimiento: _fechaVencimiento,
        subtotal: _subtotal,
        iva: _iva,
        total: _total,
        porcentajeIva: _porcentajeIva,
        estado: _estado,
        nota: _notaController.text.trim().isEmpty ? null : _notaController.text.trim(),
        fechaCreacion: widget.presupuesto?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      // Actualizar los items con el presupuestoId
      final itemsActualizados = _items
          .map((item) => item.copyWith(
                presupuestoId: widget.presupuesto?.id ?? 0,
              ))
          .toList();

      await _repository.save(presupuesto, itemsActualizados);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion ? 'Presupuesto actualizado' : 'Presupuesto creado',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _guardando = false);
    }
  }
}

// ==================== DIÁLOGO SELECTOR DE PRODUCTO ====================

class _SelectorProductoDialog extends StatefulWidget {
  final List<Producto> productos;
  final List<int> productosYaAgregados;

  const _SelectorProductoDialog({
    required this.productos,
    required this.productosYaAgregados,
  });

  @override
  State<_SelectorProductoDialog> createState() =>
      _SelectorProductoDialogState();
}

class _SelectorProductoDialogState extends State<_SelectorProductoDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Producto> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.productos;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = widget.productos);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.productos.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.modelo?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.deepOrange.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Seleccionar Producto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, SKU o modelo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final p = _filtered[index];
                        final yaAgregado =
                            widget.productosYaAgregados.contains(p.id);

                        return ListTile(
                          enabled: !yaAgregado,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: yaAgregado
                                  ? Colors.grey.shade100
                                  : Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: yaAgregado
                                  ? Colors.grey.shade400
                                  : Colors.deepOrange.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(p.nombre),
                          subtitle: Text(
                            'SKU: ${p.sku} · Stock: ${p.stockActual}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(p.precioVenta),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              if (yaAgregado)
                                Text(
                                  'Ya agregado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                          onTap: yaAgregado
                              ? null
                              : () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}