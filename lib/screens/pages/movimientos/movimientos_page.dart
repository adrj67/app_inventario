import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/movimiento_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/movimiento.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import 'movimiento_form.dart';
import '../../../widgets/export_button.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  final MovimientoRepository _repository = MovimientoRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Movimiento> _movimientos = [];
  List<Movimiento> _filtered = [];
  Map<int, Producto> _productosMap = {};
  bool _isLoading = true;
  String _filtroTipo = 'todos'; // 'todos', 'entrada', 'salida', 'ajuste'

  @override
  void initState() {
    super.initState();
    _loadMovimientos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovimientos() async {
    setState(() => _isLoading = true);
    try {
      final movimientos = await _repository.getAll();
      final productos = await _productoRepository.getAll(soloActivos: false);

      // Crear map de productos para acceso rápido
      final map = <int, Producto>{};
      for (final p in productos) {
        if (p.id != null) map[p.id!] = p;
      }

      setState(() {
        _movimientos = movimientos;
        _productosMap = map;
        _filtered = movimientos;
        _isLoading = false;
      });

      _aplicarFiltros();
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _movimientos = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<Movimiento> resultado = List.from(_movimientos);

    // Filtro por tipo / categoría
    if (_filtroTipo == 'entrada' || _filtroTipo == 'salida') {
      resultado = resultado.where((m) => m.tipo == _filtroTipo).toList();
    } else if (_filtroTipo == 'ajustes') {
      // Ajustes = movimientos cuyo motivo sea sobrante o faltante de inventario
      resultado = resultado.where((m) =>
          m.motivo == 'sobrante_inventario' ||
          m.motivo == 'faltante_inventario').toList();
    }
    // 'todos' → no filtra

    // Filtro por búsqueda
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((m) {
        final producto = _productosMap[m.productoId];
        final nombreProducto = producto?.nombre.toLowerCase() ?? '';
        return nombreProducto.contains(query) ||
            (m.motivo?.toLowerCase().contains(query) ?? false) ||
            (m.nota?.toLowerCase().contains(query) ?? false) ||
            (m.numeroFactura?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filtered = resultado);
  }

  Future<void> _abrirFormulario({Movimiento? movimiento}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MovimientoForm(movimiento: movimiento),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      _filtroTipo = 'todos';
      await _loadMovimientos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SearchField(
            controller: _searchController,
            onChanged: (_) => _aplicarFiltros(),
            hintText: 'Buscar por producto, motivo o factura...',
          ),
        ),
        _buildFiltros(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: Colors.amber.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Movimientos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} movimientos',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Movimientos',
                headers: const [
                  'ID', 'Producto', 'Tipo', 'Cantidad', 'Precio Unit.',
                  'Total', 'Motivo', 'Fecha', 'Factura',
                ],
                rows: _filtered.map((m) {
                  final producto = _productosMap[m.productoId];
                  return [
                    (m.id ?? '').toString(),
                    producto?.nombre ?? '(eliminado)',
                    m.tipo,
                    m.cantidad.toString(),
                    m.precioUnitario.toStringAsFixed(2),
                    m.total.toStringAsFixed(2),
                    m.motivo ?? '',
                    DateFormat('dd/MM/yyyy HH:mm').format(m.fecha),
                    m.numeroFactura ?? '',
                  ];
                }).toList(),
                color: Colors.amber,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Registrar Movimiento',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos', 'todos', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('Entradas', 'entrada', Icons.arrow_downward, Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('Salidas', 'salida', Icons.arrow_upward, Colors.red),
          const SizedBox(width: 8),
          _buildFilterChip('Ajustes de Inventario', 'ajustes', Icons.tune, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    IconData icon, [
    MaterialColor? color,
  ]) {
    final isSelected = _filtroTipo == value;
    final baseColor = color ?? Colors.amber;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : baseColor.shade700,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: baseColor.shade700,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? baseColor.shade700 : Colors.grey.shade300,
      ),
      onSelected: (selected) {
        setState(() => _filtroTipo = value);
        _aplicarFiltros();
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty && _filtroTipo == 'todos'
                  ? 'No hay movimientos registrados'
                  : 'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty && _filtroTipo == 'todos'
                  ? 'Presiona "Registrar Movimiento" para comenzar'
                  : 'Intenta con otros filtros',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovimientos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final movimiento = _filtered[index];
          final producto = _productosMap[movimiento.productoId];
          return _MovimientoCard(
            movimiento: movimiento,
            producto: producto,
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final Movimiento movimiento;
  final Producto? producto;
  final VoidCallback onTap;

  const _MovimientoCard({
    required this.movimiento,
    required this.producto,
    required this.onTap,
  });

  bool get _esAjusteInventario =>
      movimiento.motivo == 'sobrante_inventario' ||
      movimiento.motivo == 'faltante_inventario';

  MaterialColor _getTipoColor() {
    switch (movimiento.tipo) {
      case 'entrada':
        return Colors.green;
      case 'salida':
        return Colors.red;
      case 'ajuste':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon() {
    switch (movimiento.tipo) {
      case 'entrada':
        return Icons.arrow_downward;
      case 'salida':
        return Icons.arrow_upward;
      case 'ajuste':
        return Icons.tune;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getTipoLabel() {
    switch (movimiento.tipo) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'ajuste':
        return 'Ajuste';
      default:
        return movimiento.tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTipoColor();
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono según tipo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTipoIcon(), color: color.shade700, size: 28),
              ),
              const SizedBox(width: 16),

              // Info del producto
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto?.nombre ?? 'Producto eliminado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Text(
                            _getTipoLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              color: color.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // 🔥 Badge extra si es ajuste de inventario
                        if (_esAjusteInventario) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'Ajuste',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (movimiento.motivo != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            movimiento.motivo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(movimiento.fecha),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Cantidad
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Cantidad',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movimiento.tipo == 'salida' ? '-' : '+'}${movimiento.cantidad}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Precio / Total
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (movimiento.precioUnitario > 0) ...[
                      Text(
                        'Precio unit.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Text(
                        currencyFormat.format(movimiento.precioUnitario),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Text(
                        currencyFormat.format(movimiento.total),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color.shade700,
                        ),
                      ),
                    ] else
                      Text(
                        'Sin precio',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}