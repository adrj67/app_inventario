import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/marca_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/marca.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/export_button.dart';
import 'marca_form.dart';
import '../productos/producto_form.dart';
import 'package:provider/provider.dart';
import '../../../controllers/productos_filter_controller.dart';

class MarcasPage extends StatefulWidget {
  const MarcasPage({super.key});

  @override
  State<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends State<MarcasPage> {
  final MarcaRepository _repository = MarcaRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Marca> _marcas = [];
  List<Marca> _filtered = [];
  Map<int, List<Producto>> _productosPorMarca = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarcas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarcas() async {
    setState(() => _isLoading = true);
    try {
      final marcas = await _repository.getAll();
      final productos = await _productoRepository.getAll(soloActivos: false);

      // Agrupar productos por marcaId
      final Map<int, List<Producto>> agrupados = {};
      for (final p in productos) {
        if (p.marcaId != null) {
          agrupados.putIfAbsent(p.marcaId!, () => []).add(p);
        }
      }

      setState(() {
        _marcas = marcas;
        _filtered = marcas;
        _productosPorMarca = agrupados;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _marcas = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _marcas);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _marcas.where((m) {
        return m.nombre.toLowerCase().contains(q) ||
            (m.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Marca? marca}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MarcaForm(marca: marca),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadMarcas();
    }
  }

  Future<void> _editarProducto(Producto producto) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ProductoForm(producto: producto),
      ),
    );
    if (resultado == true) {
      await _loadMarcas();
    }
  }

  Future<void> _confirmarEliminar(Marca marca) async {
    final productosAsociados = _productosPorMarca[marca.id] ?? [];

    if (productosAsociados.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar "${marca.nombre}": tiene ${productosAsociados.length} productos asociados',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Marca'),
          ],
        ),
        content: Text('¿Eliminar "${marca.nombre}"?'),
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
      await _repository.delete(marca.id!);
      await _loadMarcas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SearchField(
            controller: _searchController,
            onChanged: _filtrar,
            hintText: 'Buscar marcas...',
          ),
        ),
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
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_offer, color: Colors.teal.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} marcas · ${_productosPorMarca.values.fold(0, (sum, list) => sum + list.length)} productos asociados',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Marcas',
                headers: const [
                  'ID', 'Nombre', 'Descripción', 'Productos Asociados', 'Estado',
                ],
                rows: _filtered.map((m) => [
                  (m.id ?? '').toString(),
                  m.nombre,
                  m.descripcion ?? '',
                  (_productosPorMarca[m.id]?.length ?? 0).toString(),
                  m.activa ? 'Activa' : 'Inactiva',
                ]).toList(),
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Marca',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No hay marcas' : 'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final marca = _filtered[index];
        final productos = _productosPorMarca[marca.id] ?? [];
        return _MarcaCard(
          marca: marca,
          productos: productos,
          onEdit: () => _abrirFormulario(marca: marca),
          onDelete: () => _confirmarEliminar(marca),
          onProductoTap: _editarProducto,
        );
      },
    );
  }
}

// ==================== WIDGET CARD ====================

class _MarcaCard extends StatelessWidget {
  final Marca marca;
  final List<Producto> productos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Producto) onProductoTap;

  const _MarcaCard({
    required this.marca,
    required this.productos,
    required this.onEdit,
    required this.onDelete,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    final valorTotal = productos.fold<double>(
      0,
      (sum, p) => sum + (p.stockActual * p.precioCompra),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              marca.nombre.substring(0, 2).toUpperCase(),
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          marca.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (marca.descripcion != null)
              Text(
                marca.descripcion!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: productos.isEmpty ? Colors.grey.shade100 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${productos.length} producto${productos.length != 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      color: productos.isEmpty ? Colors.grey.shade600 : Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (valorTotal > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Valor: ${currencyFormat.format(valorTotal)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: onEdit,
              tooltip: 'Editar marca',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: onDelete,
              tooltip: 'Eliminar marca',
            ),
          ],
        ),
        children: [
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'No hay productos con esta marca',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            // Encabezado de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildHeaderText('PRODUCTO')),
                  Expanded(
                    flex: 1,
                    child: _buildHeaderText('STOCK', center: true),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeaderText('PRECIO VENTA', right: true),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Lista de productos
            ...productos.map((p) => _buildItemProducto(context, p)),
            // Footer con acción
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                        context.read<ProductosFilterController>().filtrarPorMarca(marca.id!);
                    },
                    //onPressed: () => _verTodosProductos(context, marca),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Ver todos en Productos'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, {bool center = false, bool right = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : (right ? TextAlign.right : TextAlign.left),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildItemProducto(BuildContext context, Producto p) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => onProductoTap(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'SKU: ${p.sku}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                p.stockActual.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: p.estaAgotado
                      ? Colors.red.shade700
                      : (p.tieneStockBajo ? Colors.orange.shade700 : Colors.grey.shade800),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                currencyFormat.format(p.precioVenta),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /*void _verTodosProductos(BuildContext context, Marca marca) {
    // 🔥 Enviar filtro al controller
    context.read<ProductosFilterController>().filtrarPorMarca(marca.id!);
  }*/

  /* void _verTodosProductos(BuildContext context) {
    // Por ahora mostramos un SnackBar informativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Andá a "Productos" y filtrá por "${marca.nombre}"'),
        backgroundColor: Colors.teal.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }*/
}