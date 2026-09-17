import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/producto_repository.dart';
import '../../../database/movimiento_repository.dart';
import '../../../database/categoria_repository.dart';
import '../../../database/proveedor_repository.dart';
import '../../../models/producto.dart';
import '../../../models/movimiento.dart';
import '../../../models/categoria.dart';
import '../../../models/proveedor.dart';

class ReporteDetallePage extends StatefulWidget {
  final String tipo;
  final String titulo;
  final MaterialColor color;

  const ReporteDetallePage({
    super.key,
    required this.tipo,
    required this.titulo,
    required this.color,
  });

  @override
  State<ReporteDetallePage> createState() => _ReporteDetallePageState();
}

class _ReporteDetallePageState extends State<ReporteDetallePage> {
  final ProductoRepository _productoRepo = ProductoRepository();
  final MovimientoRepository _movimientoRepo = MovimientoRepository();
  final CategoriaRepository _categoriaRepo = CategoriaRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  bool _isLoading = true;
  List<dynamic> _items = [];
  String _subtitulo = '';

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);
    try {
      switch (widget.tipo) {
        case 'stock_bajo':
          await _cargarStockBajo();
          break;
        case 'agotados':
          await _cargarAgotados();
          break;
        case 'mas_movidos':
          await _cargarMasMovidos();
          break;
        case 'por_categoria':
          await _cargarPorCategoria();
          break;
        case 'por_proveedor':
          await _cargarPorProveedor();
          break;
        case 'historial':
          await _cargarHistorial();
          break;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cargarStockBajo() async {
    _items = await _productoRepo.getStockBajo();
    _subtitulo = '${_items.length} productos necesitan reposición';
  }

  Future<void> _cargarAgotados() async {
    _items = await _productoRepo.getAgotados();
    _subtitulo = '${_items.length} productos sin stock';
  }

  Future<void> _cargarMasMovidos() async {
    final movimientos = await _movimientoRepo.getAll();
    final productos = await _productoRepo.getAll();

    // Contar movimientos por producto
    final Map<int, int> conteo = {};
    for (final m in movimientos) {
      conteo[m.productoId] = (conteo[m.productoId] ?? 0) + 1;
    }

    // Ordenar productos por cantidad de movimientos
    final lista = <Map<String, dynamic>>[];
    for (final p in productos) {
      final count = conteo[p.id] ?? 0;
      if (count > 0) {
        lista.add({'producto': p, 'cantidad': count});
      }
    }
    lista.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    _items = lista;
    _subtitulo = '${lista.length} productos con movimientos';
  }

  Future<void> _cargarPorCategoria() async {
    final productos = await _productoRepo.getAll();
    final categorias = await _categoriaRepo.getAll();

    final Map<int?, List<Producto>> grupos = {};
    for (final p in productos) {
      grupos.putIfAbsent(p.categoriaId, () => []).add(p);
    }

    final lista = <Map<String, dynamic>>[];
    for (final cat in categorias) {
      final prods = grupos[cat.id] ?? [];
      if (prods.isNotEmpty) {
        final valor = prods.fold<double>(
          0,
          (sum, p) => sum + (p.stockActual * p.precioCompra),
        );
        lista.add({
          'categoria': cat,
          'productos': prods,
          'valor': valor,
        });
      }
    }
    // Sin categoría
    if (grupos.containsKey(null)) {
      final prods = grupos[null]!;
      final valor = prods.fold<double>(
        0,
        (sum, p) => sum + (p.stockActual * p.precioCompra),
      );
      lista.add({
        'categoria': null,
        'productos': prods,
        'valor': valor,
      });
    }

    _items = lista;
    _subtitulo = '${lista.length} categorías con productos';
  }

  Future<void> _cargarPorProveedor() async {
    final productos = await _productoRepo.getAll();
    final proveedores = await _proveedorRepo.getAll();

    final Map<int?, List<Producto>> grupos = {};
    for (final p in productos) {
      grupos.putIfAbsent(p.proveedorId, () => []).add(p);
    }

    final lista = <Map<String, dynamic>>[];
    for (final prov in proveedores) {
      final prods = grupos[prov.id] ?? [];
      if (prods.isNotEmpty) {
        final valor = prods.fold<double>(
          0,
          (sum, p) => sum + (p.stockActual * p.precioCompra),
        );
        lista.add({
          'proveedor': prov,
          'productos': prods,
          'valor': valor,
        });
      }
    }
    if (grupos.containsKey(null)) {
      final prods = grupos[null]!;
      final valor = prods.fold<double>(
        0,
        (sum, p) => sum + (p.stockActual * p.precioCompra),
      );
      lista.add({
        'proveedor': null,
        'productos': prods,
        'valor': valor,
      });
    }

    _items = lista;
    _subtitulo = '${lista.length} proveedores con productos';
  }

  Future<void> _cargarHistorial() async {
    _items = await _movimientoRepo.getAll();
    _subtitulo = '${_items.length} movimientos registrados';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: widget.color.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: widget.color.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: widget.color.shade700),
                      const SizedBox(width: 8),
                      Text(
                        _subtitulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.color.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay datos para este reporte',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    switch (widget.tipo) {
      case 'stock_bajo':
      case 'agotados':
        return _buildListaProductos();
      case 'mas_movidos':
        return _buildListaMasMovidos();
      case 'por_categoria':
        return _buildListaAgrupada('categoria');
      case 'por_proveedor':
        return _buildListaAgrupada('proveedor');
      case 'historial':
        return _buildListaHistorial();
      default:
        return const SizedBox();
    }
  }

  Widget _buildListaProductos() {
    //final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final p = _items[index] as Producto;
        final color = p.estaAgotado ? Colors.red : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    p.estaAgotado ? Icons.remove_shopping_cart : Icons.warning_amber,
                    color: color.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${p.sku}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${p.stockActual}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Mín: ${p.stockMinimo}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reponer: ${p.stockMinimo - p.stockActual < 1 ? 1 : p.stockMinimo - p.stockActual + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaMasMovidos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index] as Map<String, dynamic>;
        final p = item['producto'] as Producto;
        final count = item['cantidad'] as int;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.color.shade700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            title: Text(
              p.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('SKU: ${p.sku}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count mov.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.color.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaAgrupada(String tipo) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index] as Map<String, dynamic>;
        final esCategoria = tipo == 'categoria';

        // 🔥 Obtener el nombre según el tipo
        String nombre;
        if (esCategoria) {
          final cat = item['categoria'] as Categoria?;
          nombre = cat?.nombre ?? 'Sin categoría';
        } else {
          final prov = item['proveedor'] as Proveedor?;
          nombre = prov?.nombre ?? 'Sin proveedor';
        }

        final productos = item['productos'] as List<Producto>;
        final valor = item['valor'] as double;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esCategoria ? Icons.category : Icons.business,
                color: widget.color.shade700,
              ),
            ),
            title: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              '${productos.length} productos · ${currencyFormat.format(valor)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            children: productos.map((p) {
              return ListTile(
                leading: Icon(Icons.inventory_2, color: Colors.grey.shade600),
                title: Text(p.nombre),
                subtitle: Text('SKU: ${p.sku} · Stock: ${p.stockActual}'),
                trailing: Text(
                  currencyFormat.format(p.stockActual * p.precioCompra),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListaHistorial() {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final m = _items[index] as Movimiento;
        final esEntrada = m.tipo == 'entrada';
        final color = esEntrada ? Colors.green : Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                color: color.shade700,
                size: 20,
              ),
            ),
            title: Text(
              '${esEntrada ? "+" : "-"}${m.cantidad} unidades',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
            subtitle: Text(
              '${m.motivo ?? "sin motivo"} · ${dateFormat.format(m.fecha)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: m.precioUnitario > 0
                ? Text(
                    currencyFormat.format(m.total),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : null,
          ),
        );
      },
    );
  }
}