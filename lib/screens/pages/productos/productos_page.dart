import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/producto_repository.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import 'producto_form.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final ProductoRepository _repository = ProductoRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Producto> _productos = [];
  List<Producto> _filtered = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos'; // 'todos', 'stock_bajo', 'agotados'

  // Estadísticas
  int _totalProductos = 0;
  int _totalStockBajo = 0;
  int _totalAgotados = 0;
  double _valorInventario = 0;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);

    try {
      final lista = await _repository.getAll(soloActivos: true);
      final stockBajo = await _repository.getStockBajo();
      final agotados = await _repository.getAgotados();
      final valor = await _repository.getValorInventario();

      setState(() {
        _productos = lista;
        _filtered = lista;
        _totalProductos = lista.length;
        _totalStockBajo = stockBajo.length;
        _totalAgotados = agotados.length;
        _valorInventario = valor;
        _isLoading = false;
      });

      _aplicarFiltros();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      setState(() {
        _productos = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<Producto> resultado = List.from(_productos);

    // Filtro por estado
    if (_filtroEstado == 'stock_bajo') {
      resultado = resultado.where((p) => p.tieneStockBajo).toList();
    } else if (_filtroEstado == 'agotados') {
      resultado = resultado.where((p) => p.estaAgotado).toList();
    }

    // Filtro por búsqueda
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((p) {
        return p.nombre.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            p.codigoBarras.toLowerCase().contains(query) ||
            (p.modelo?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filtered = resultado);
  }

  Future<void> _abrirFormulario({Producto? producto}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ProductoForm(producto: producto),
      ),
    );

    if (resultado == true) {
      _searchController.clear();
      _filtroEstado = 'todos';
      await _loadProductos();
    }
  }

  Future<void> _confirmarEliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Producto'),
          ],
        ),
        content: Text('¿Estás seguro que deseas eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _repository.delete(producto.id!);
      await _loadProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildEstadisticas(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SearchField(
            controller: _searchController,
            onChanged: (_) => _aplicarFiltros(),
            hintText: 'Buscar por nombre, SKU, código o modelo...',
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} de $_totalProductos productos',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Nuevo Producto',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              titulo: 'Total Productos',
              valor: '$_totalProductos',
              icono: Icons.inventory,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              titulo: 'Stock Bajo',
              valor: '$_totalStockBajo',
              icono: Icons.warning_amber,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              titulo: 'Agotados',
              valor: '$_totalAgotados',
              icono: Icons.remove_shopping_cart,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildStatCard(
              titulo: 'Valor del Inventario',
              valor: currencyFormat.format(_valorInventario),
              icono: Icons.attach_money,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          _buildFilterChip('Stock Bajo', 'stock_bajo', Icons.warning_amber),
          const SizedBox(width: 8),
          _buildFilterChip('Agotados', 'agotados', Icons.remove_shopping_cart),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: Colors.blue.shade700,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
      ),
      onSelected: (selected) {
        setState(() => _filtroEstado = value);
        _aplicarFiltros();
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty && _filtroEstado == 'todos'
                  ? 'No hay productos registrados'
                  : 'No se encontraron productos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty && _filtroEstado == 'todos'
                  ? 'Presiona "Nuevo Producto" para comenzar'
                  : 'Intenta con otros filtros o términos',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProductos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final producto = _filtered[index];
          return _ProductoCard(
            producto: producto,
            onTap: () => _abrirFormulario(producto: producto),
            onDelete: () => _confirmarEliminar(producto),
          );
        },
      ),
    );
  }
}

// ==================== WIDGET CARD ====================

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductoCard({
    required this.producto,
    required this.onTap,
    required this.onDelete,
  });

  MaterialColor _colorEstado() {
    if (producto.estaAgotado) return Colors.red;
    if (producto.tieneStockBajo) return Colors.orange;
    return Colors.green;
  }

  String _textoEstado() {
    if (producto.estaAgotado) return 'Sin stock';
    if (producto.tieneStockBajo) return 'Stock bajo';
    return 'En stock';
  }

  IconData _iconoEstado() {
    if (producto.estaAgotado) return Icons.remove_shopping_cart;
    if (producto.tieneStockBajo) return Icons.warning_amber;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado();
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

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
              // Icono del producto
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconoEstado(),
                  color: color.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Información principal
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
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
                        Icon(Icons.qr_code, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          producto.sku,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (producto.modelo != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.tag, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            producto.modelo!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Stock
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${producto.stockActual} ${producto.unidadMedida}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mín: ${producto.stockMinimo}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Precios
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Compra',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      currencyFormat.format(producto.precioCompra),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Venta',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      currencyFormat.format(producto.precioVenta),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.shade200),
                ),
                child: Text(
                  _textoEstado(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.shade700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}