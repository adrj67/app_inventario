import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../database/producto_repository.dart';
import '../../../database/proveedor_repository.dart';
import '../../../models/producto.dart';
import '../../../models/proveedor.dart';

class ProductoForm extends StatefulWidget {
  final Producto? producto;

  const ProductoForm({super.key, this.producto});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  final ProductoRepository _repository = ProductoRepository();
  final ProveedorRepository _proveedorRepository = ProveedorRepository();

  // ==================== CONTROLLERS ====================
  late final TextEditingController _skuController;
  late final TextEditingController _codigoBarrasController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _modeloController;
  late final TextEditingController _stockActualController;
  late final TextEditingController _stockMinimoController;
  late final TextEditingController _stockMaximoController;
  late final TextEditingController _precioCompraController;
  late final TextEditingController _precioVentaController;
  late final TextEditingController _precioSugeridoController;
  late final TextEditingController _numeroFacturaController;
  late final TextEditingController _pesoController;
  late final TextEditingController _dimensionesController;
  late final TextEditingController _mesesGarantiaController;
  late final TextEditingController _notaController;

  // ==================== STATE ====================
  String _unidadMedida = 'Unidad';
  bool _estaActivo = true;
  bool _estaDisponible = true;
  DateTime _fechaCompra = DateTime.now();
  //DateTime? _fechaFinGarantia;
  int? _proveedorId;
  bool _guardando = false;

  // Lista de proveedores disponibles
  List<Proveedor> _proveedores = [];
  bool _cargandoProveedores = true;

  final List<String> _unidades = [
    'Unidad',
    'Kg',
    'Litro',
    'Metro',
    'Caja',
    'Paquete',
    'Docena',
    'Par',
  ];

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;

    _skuController = TextEditingController(text: p?.sku ?? '');
    _codigoBarrasController = TextEditingController(text: p?.codigoBarras ?? '');
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _modeloController = TextEditingController(text: p?.modelo ?? '');
    _stockActualController = TextEditingController(text: p?.stockActual.toString() ?? '0');
    _stockMinimoController = TextEditingController(text: p?.stockMinimo.toString() ?? '0');
    _stockMaximoController = TextEditingController(text: p?.stockMaximo.toString() ?? '0');
    _precioCompraController = TextEditingController(text: p?.precioCompra.toString() ?? '0');
    _precioVentaController = TextEditingController(text: p?.precioVenta.toString() ?? '0');
    _precioSugeridoController = TextEditingController(text: p?.precioSugerido?.toString() ?? '');
    _numeroFacturaController = TextEditingController(text: p?.numeroFactura ?? '');
    _pesoController = TextEditingController(text: p?.peso?.toString() ?? '');
    _dimensionesController = TextEditingController(text: p?.dimensiones ?? '');
    _mesesGarantiaController = TextEditingController(text: p?.mesesGarantia?.toString() ?? '');
    _notaController = TextEditingController(text: p?.nota ?? '');

    _unidadMedida = p?.unidadMedida ?? 'Unidad';
    _estaActivo = p?.estaActivo ?? true;
    _estaDisponible = p?.estaDisponible ?? true;
    _fechaCompra = p?.fechaCompra ?? DateTime.now();
    //_fechaFinGarantia = p?.fechaFinGarantia;
    _proveedorId = p?.proveedorId;

    _cargarProveedores();

    // Listener para recalcular precio sugerido
    _precioCompraController.addListener(_recalcularPrecioSugerido);
  }

  @override
  void dispose() {
    _skuController.dispose();
    _codigoBarrasController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _modeloController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    _stockMaximoController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _precioSugeridoController.dispose();
    _numeroFacturaController.dispose();
    _pesoController.dispose();
    _dimensionesController.dispose();
    _mesesGarantiaController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _cargarProveedores() async {
    try {
      final lista = await _proveedorRepository.getAll();
      setState(() {
        _proveedores = lista;
        _cargandoProveedores = false;
      });
    } catch (e) {
      debugPrint('Error cargando proveedores: $e');
      setState(() => _cargandoProveedores = false);
    }
  }

  void _recalcularPrecioSugerido() {
    final compra = double.tryParse(_precioCompraController.text) ?? 0;
    if (compra > 0) {
      // Margen sugerido: 40%
      final sugerido = compra * 1.40;
      _precioSugeridoController.text = sugerido.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: Colors.blue.shade700,
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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  _buildSeccionDatosBasicos(),
                  const SizedBox(height: 16),
                  _buildSeccionClasificacion(),
                  const SizedBox(height: 16),
                  _buildSeccionStock(),
                  const SizedBox(height: 16),
                  _buildSeccionPrecios(),
                  const SizedBox(height: 16),
                  _buildSeccionCompra(),
                  const SizedBox(height: 16),
                  _buildSeccionCaracteristicas(),
                  const SizedBox(height: 16),
                  _buildSeccionEstado(),
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

  Widget _buildSeccionDatosBasicos() {
    return _buildCard(
      titulo: 'Datos Básicos',
      icono: Icons.info_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _skuController,
                label: 'SKU / Código Interno *',
                icon: Icons.qr_code,
                validator: (v) => v?.trim().isEmpty ?? true
                    ? 'El SKU es obligatorio'
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _codigoBarrasController,
                label: 'Código de Barras',
                icon: Icons.barcode_reader,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nombreController,
          label: 'Nombre del Producto *',
          icon: Icons.inventory_2,
          validator: (v) => v?.trim().isEmpty ?? true
              ? 'El nombre es obligatorio'
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descripcionController,
          label: 'Descripción',
          icon: Icons.description,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _modeloController,
          label: 'Modelo',
          icon: Icons.tag,
        ),
      ],
    );
  }

  Widget _buildSeccionClasificacion() {
    return _buildCard(
      titulo: 'Clasificación y Proveedor',
      icono: Icons.category,
      children: [
        Row(
          children: [
            Expanded(
              child: _cargandoProveedores
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _proveedorId,
                      decoration: InputDecoration(
                        labelText: 'Proveedor',
                        prefixIcon: Icon(Icons.business, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Sin proveedor'),
                        ),
                        ..._proveedores.map((p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.nombre),
                            )),
                      ],
                      onChanged: (v) => setState(() => _proveedorId = v),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _numeroFacturaController,
                label: 'N° de Factura',
                icon: Icons.receipt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionStock() {
    return _buildCard(
      titulo: 'Stock',
      icono: Icons.warehouse,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _stockActualController,
                label: 'Stock Actual *',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _stockMinimoController,
                label: 'Stock Mínimo *',
                icon: Icons.warning_amber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _stockMaximoController,
                label: 'Stock Máximo',
                icon: Icons.vertical_align_top,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _unidadMedida,
                decoration: InputDecoration(
                  labelText: 'Unidad de Medida',
                  prefixIcon: Icon(Icons.straighten, color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _unidades.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u),
                    )).toList(),
                onChanged: (v) => setState(() => _unidadMedida = v ?? 'Unidad'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionPrecios() {
    return _buildCard(
      titulo: 'Precios',
      icono: Icons.attach_money,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _precioCompraController,
                label: 'Precio de Compra *',
                icon: Icons.shopping_cart,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(v!) == null) return 'Número inválido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _precioSugeridoController,
                label: 'Precio Sugerido (40% margen)',
                icon: Icons.lightbulb_outline,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _precioVentaController,
                label: 'Precio de Venta *',
                icon: Icons.sell,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(v!) == null) return 'Número inválido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildIndicadorGanancia(),
      ],
    );
  }

  Widget _buildIndicadorGanancia() {
    final compra = double.tryParse(_precioCompraController.text) ?? 0;
    final venta = double.tryParse(_precioVentaController.text) ?? 0;
    final ganancia = venta - compra;
    final porcentaje = compra > 0 ? (ganancia / compra) * 100 : 0;

    final color = ganancia > 0 ? Colors.green : (ganancia < 0 ? Colors.red : Colors.grey);
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            ganancia > 0 ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            'Ganancia: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: color.shade700),
          ),
          Text(
            currencyFormat.format(ganancia),
            style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700),
          ),
          const SizedBox(width: 16),
          Text(
            '(${porcentaje.toStringAsFixed(1)}%)',
            style: TextStyle(color: color.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCompra() {
    return _buildCard(
      titulo: 'Fecha de Compra',
      icono: Icons.calendar_today,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _seleccionarFechaCompra(),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Compra',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fechaCompra),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionCaracteristicas() {
    return _buildCard(
      titulo: 'Características Adicionales',
      icono: Icons.straighten,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _pesoController,
                label: 'Peso (kg)',
                icon: Icons.scale,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _dimensionesController,
                label: 'Dimensiones (ej: 30x20x10 cm)',
                icon: Icons.crop_square,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _mesesGarantiaController,
                label: 'Garantía (meses)',
                icon: Icons.verified,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notaController,
          label: 'Notas / Observaciones',
          icon: Icons.note,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSeccionEstado() {
    return _buildCard(
      titulo: 'Estado',
      icono: Icons.toggle_on,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _estaActivo ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _estaActivo ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: _estaActivo,
                      onChanged: (v) => setState(() => _estaActivo = v),
                      activeThumbColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _estaActivo ? 'Producto Activo' : 'Producto Inactivo',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _estaActivo ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _estaDisponible ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _estaDisponible ? Colors.blue.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: _estaDisponible,
                      onChanged: (v) => setState(() => _estaDisponible = v),
                      activeThumbColor: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _estaDisponible ? 'Disponible' : 'No disponible',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _estaDisponible ? Colors.blue.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              backgroundColor: Colors.blue.shade700,
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
                  : (_esEdicion ? 'Actualizar Producto' : 'Guardar Producto'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.blue.shade700, size: 20),
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
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Future<void> _seleccionarFechaCompra() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompra,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'AR'),
    );
    if (fecha != null) {
      setState(() => _fechaCompra = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {

      final mesesGarantia = int.tryParse(_mesesGarantiaController.text);
      final fechaFinGarantia = mesesGarantia != null && mesesGarantia > 0
          ? DateTime(
              _fechaCompra.year,
              _fechaCompra.month + mesesGarantia,
              _fechaCompra.day,
            )
          : null;

      final producto = Producto(
        id: widget.producto?.id,
        sku: _skuController.text.trim(),
        codigoBarras: _codigoBarrasController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: _textoONull(_descripcionController.text),
        modelo: _textoONull(_modeloController.text),
        proveedorId: _proveedorId,
        stockActual: int.tryParse(_stockActualController.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 0,
        stockMaximo: int.tryParse(_stockMaximoController.text) ?? 0,
        unidadMedida: _unidadMedida,
        precioCompra: double.tryParse(_precioCompraController.text) ?? 0,
        precioVenta: double.tryParse(_precioVentaController.text) ?? 0,
        precioSugerido: double.tryParse(_precioSugeridoController.text),
        fechaCompra: _fechaCompra,
        numeroFactura: _textoONull(_numeroFacturaController.text),
        peso: double.tryParse(_pesoController.text),
        dimensiones: _textoONull(_dimensionesController.text),
        mesesGarantia: mesesGarantia, //int.tryParse(_mesesGarantiaController.text),
        fechaFinGarantia: fechaFinGarantia,
        estaActivo: _estaActivo,
        estaDisponible: _estaDisponible,
        estado: _calcularEstado(),
        fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now(),
        fechaUltimaModificacion: DateTime.now(),
        nota: _textoONull(_notaController.text),
      );

      await _repository.save(producto);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _guardando = false);
    }
  }

  String _calcularEstado() {
    final stock = int.tryParse(_stockActualController.text) ?? 0;
    final minimo = int.tryParse(_stockMinimoController.text) ?? 0;

    if (stock <= 0) return 'agotado';
    if (stock <= minimo) return 'stock_bajo';
    return 'en_stock';
  }

  String? _textoONull(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }
}