import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../database/movimiento_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/movimiento.dart';
import '../../../models/producto.dart';

class MovimientoForm extends StatefulWidget {
  final Movimiento? movimiento;

  const MovimientoForm({super.key, this.movimiento});

  @override
  State<MovimientoForm> createState() => _MovimientoFormState();
}

class _MovimientoFormState extends State<MovimientoForm> {
  final _formKey = GlobalKey<FormState>();
  final MovimientoRepository _repository = MovimientoRepository();
  final ProductoRepository _productoRepository = ProductoRepository();

  late final TextEditingController _cantidadController;
  late final TextEditingController _precioController;
  late final TextEditingController _notaController;
  late final TextEditingController _numeroFacturaController;

  String _tipo = 'entrada';
  String? _motivo;
  DateTime _fecha = DateTime.now();
  int? _productoId;
  Producto? _productoSeleccionado;
  List<Producto> _productos = [];
  bool _cargandoProductos = true;
  bool _guardando = false;

  final List<String> _motivosEntrada = [
    'compra',
    'devolucion_cliente',
    'sobrante_inventario',
    'otro',
  ];
  final List<String> _motivosSalida = [
    'venta',
    'perdida',
    'rotura',
    'faltante_inventario',
    'devolucion_proveedor',
    'otro',
  ];
  
  @override
  void initState() {
    super.initState();
    final m = widget.movimiento;
    _cantidadController = TextEditingController(text: m?.cantidad.toString() ?? '');
    _precioController = TextEditingController(
      text: m?.precioUnitario.toString() ?? '',
    );
    _notaController = TextEditingController(text: m?.nota ?? '');
    _numeroFacturaController = TextEditingController(text: m?.numeroFactura ?? '');
    _tipo = m?.tipo ?? 'entrada';
    _motivo = m?.motivo;
    _fecha = m?.fecha ?? DateTime.now();
    _productoId = m?.productoId;
    _cargarProductos();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    _notaController.dispose();
    _numeroFacturaController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final lista = await _productoRepository.getAll();
      setState(() {
        _productos = lista;
        _productoSeleccionado =
            lista.where((p) => p.id == _productoId).firstOrNull;
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() => _cargandoProductos = false);
    }
  }

  List<String> get _motivosDisponibles {
    if (_tipo == 'entrada') return _motivosEntrada;
    return _motivosSalida;   // 2 opciones ahora
  }

  Color get _tipoColor {
    return _tipo == 'entrada' ? Colors.green.shade700 : Colors.red.shade700;
  }

/*
  IconData get _tipoIcon {
    if (_tipo == 'entrada') return Icons.arrow_downward;
    if (_tipo == 'salida') return Icons.arrow_upward;
    return Icons.tune;
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Movimiento'),
        backgroundColor: _tipoColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Selector de tipo
                  _buildSelectorTipo(),
                  const SizedBox(height: 16),

                  // Producto
                  _buildSeccionProducto(),
                  const SizedBox(height: 16),

                  // Detalles del movimiento
                  _buildSeccionDetalles(),
                  const SizedBox(height: 16),

                  // Vista previa del stock
                  if (_productoSeleccionado != null && _cantidadController.text.isNotEmpty)
                    _buildPreviewStock(),
                  const SizedBox(height: 24),

                  // Botones
                  _buildBotones(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Movimiento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTipoBoton('entrada', 'Entrada (suma stock)', Icons.arrow_downward, Colors.green),
                const SizedBox(width: 12),
                _buildTipoBoton('salida', 'Salida (resta stock)', Icons.arrow_upward, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoBoton(String tipo, String label, IconData icon, MaterialColor color) {
    final isSelected = _tipo == tipo;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tipo = tipo;
            _motivo = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.shade700 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color.shade700 : Colors.grey.shade500,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color.shade700 : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionProducto() {
    return _buildCard(
      titulo: 'Producto',
      icono: Icons.inventory_2,
      children: [
        if (_cargandoProductos)
          const Center(child: CircularProgressIndicator())
        else if (_productos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No hay productos cargados. Creá un producto primero.',
              style: TextStyle(color: Colors.red.shade700),
            ),
          )
        else
          DropdownButtonFormField<int>(
            initialValue: _productoId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Seleccionar Producto *',
              prefixIcon: Icon(Icons.inventory, color: Colors.amber.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _productos.map((p) {
              return DropdownMenuItem<int>(
                value: p.id,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.estaAgotado
                            ? Colors.red.shade50
                            : p.tieneStockBajo
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stock: ${p.stockActual}',
                        style: TextStyle(
                          fontSize: 11,
                          color: p.estaAgotado
                              ? Colors.red.shade700
                              : p.tieneStockBajo
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _productoId = v;
                _productoSeleccionado =
                    _productos.where((p) => p.id == v).firstOrNull;
                if (_productoSeleccionado != null && _precioController.text.isEmpty) {
                  _precioController.text =
                      _productoSeleccionado!.precioCompra.toString();
                }
              });
            },
            validator: (v) => v == null ? 'Seleccioná un producto' : null,
          ),
      ],
    );
  }

  Widget _buildSeccionDetalles() {
    return _buildCard(
      titulo: 'Detalles',
      icono: Icons.info_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cantidadController,
                label: 'Cantidad *',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Requerido';
                  final n = int.tryParse(v!);
                  if (n == null || n <= 0) return 'Mayor a 0';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _precioController,
                label: 'Precio Unitario',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _motivo,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  prefixIcon: Icon(Icons.label, color: Colors.amber.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin especificar'),
                  ),
                  ..._motivosDisponibles.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.replaceAll('_', ' ').toUpperCase()),
                      )),
                ],
                onChanged: (v) => setState(() => _motivo = v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.amber.shade700),
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
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _numeroFacturaController,
          label: 'N° de Factura (opcional)',
          icon: Icons.receipt,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notaController,
          label: 'Nota / Observaciones',
          icon: Icons.note,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPreviewStock() {
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final stockActual = _productoSeleccionado!.stockActual;
    final nuevoStock = _tipo == 'salida' ? stockActual - cantidad : stockActual + cantidad;
    final esValido = nuevoStock >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esValido ? Colors.blue.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esValido ? Colors.blue.shade200 : Colors.red.shade300,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esValido ? Icons.preview : Icons.error,
                  color: esValido ? Colors.blue.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vista Previa del Stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: esValido ? Colors.blue.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStockItem('Stock Actual', '$stockActual', Colors.grey),
                Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                _buildStockItem(
                  'Nuevo Stock',
                  '$nuevoStock',
                  esValido ? Colors.green : Colors.red,
                ),
              ],
            ),
            if (!esValido) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ El stock quedaría en negativo. Verificá la cantidad.',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(String label, String valor, MaterialColor color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color.shade700,
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
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _tipoColor,
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
              _guardando ? 'Registrando...' : 'Registrar Movimiento',
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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.amber.shade700, size: 20),
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
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.amber.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'AR'),
    );
    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final movimiento = Movimiento(
        id: widget.movimiento?.id,
        productoId: _productoId!,
        tipo: _tipo,
        cantidad: int.parse(_cantidadController.text),
        precioUnitario: double.tryParse(_precioController.text) ?? 0,
        motivo: _motivo,
        nota: _notaController.text.trim().isEmpty ? null : _notaController.text.trim(),
        numeroFactura: _numeroFacturaController.text.trim().isEmpty
            ? null
            : _numeroFacturaController.text.trim(),
        fecha: _fecha,
        fechaCreacion: DateTime.now(),
      );

      await _repository.save(movimiento);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movimiento registrado. Stock actualizado.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _guardando = false);
    }
  }
}