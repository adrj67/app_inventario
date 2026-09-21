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
//import '../../../widgets/export_button.dart';
import '../../../services/export_helper.dart';

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
        actions: [
          // 🔥 Botón Exportar (solo si hay datos cargados)
          if (!_isLoading && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildBotonExportar(),
            ),
        ],
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

  // ==================== EXPORTACIÓN ====================

  Widget _buildBotonExportar() {
    return Tooltip(
      message: 'Exportar a CSV o PDF',
      child: OutlinedButton.icon(
        onPressed: () => _exportarReporte(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.file_download, size: 18),
        label: const Text(
          'Exportar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _exportarReporte(BuildContext context) {
    final data = _prepararDatosExportacion();
    if (data == null) return;

    ExportHelper.mostrarDialogoExportacion(
      context: context,
      titulo: widget.titulo,
      headers: data['headers'] as List<String>,
      rows: data['rows'] as List<List<String>>,
    );
  }

  /// Prepara los headers y rows según el tipo de reporte
  Map<String, dynamic>? _prepararDatosExportacion() {
    switch (widget.tipo) {
      case 'stock_bajo':
      case 'agotados':
        return _prepararDatosProductos();
      case 'mas_movidos':
        return _prepararDatosMasMovidos();
      case 'por_categoria':
      case 'por_proveedor':
        return _prepararDatosAgrupados();
      case 'historial':
        return _prepararDatosHistorial();
      default:
        return null;
    }
  }

  // ==================== PREPARAR DATOS POR TIPO ====================

  Map<String, dynamic> _prepararDatosProductos() {
    final headers = [
      'ID',
      'SKU',
      'Nombre',
      'Modelo',
      'Stock Actual',
      'Stock Mínimo',
      'Reponer',
      'Estado',
    ];

    final rows = _items.map((item) {
      final p = item as Producto;
      final reponer = p.stockMinimo - p.stockActual < 1
          ? 1
          : p.stockMinimo - p.stockActual + 1;
      return [
        (p.id ?? '').toString(),
        p.sku,
        p.nombre,
        p.modelo ?? '',
        p.stockActual.toString(),
        p.stockMinimo.toString(),
        reponer.toString(),
        p.estaAgotado ? 'Agotado' : 'Stock Bajo',
      ];
    }).toList();

    return {'headers': headers, 'rows': rows};
  }

  Map<String, dynamic> _prepararDatosMasMovidos() {
    final headers = [
      'Posición',
      'SKU',
      'Nombre',
      'Cantidad Movimientos',
      'Stock Actual',
    ];

    final rows = <List<String>>[];
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i] as Map<String, dynamic>;
      final p = item['producto'] as Producto;
      final count = item['cantidad'] as int;
      rows.add([
        '${i + 1}',
        p.sku,
        p.nombre,
        count.toString(),
        p.stockActual.toString(),
      ]);
    }

    return {'headers': headers, 'rows': rows};
  }

  Map<String, dynamic> _prepararDatosAgrupados() {
    final esCategoria = widget.tipo == 'por_categoria';
    final headers = [
      esCategoria ? 'Categoría' : 'Proveedor',
      'Producto',
      'SKU',
      'Stock Actual',
      'Precio Compra',
      'Valor Stock',
    ];

    final rows = <List<String>>[];
    for (final item in _items) {
      final map = item as Map<String, dynamic>;

      // 🔥 Extraer el nombre según el tipo (evita el error de Object)
      String nombreGrupo;
      if (esCategoria) {
        final cat = map['categoria'] as Categoria?;
        nombreGrupo = cat?.nombre ?? 'Sin categoría';
      } else {
        final prov = map['proveedor'] as Proveedor?;
        nombreGrupo = prov?.nombre ?? 'Sin proveedor';
      }

      final productos = map['productos'] as List<Producto>;

      for (final p in productos) {
        rows.add([
          nombreGrupo,
          p.nombre,
          p.sku,
          p.stockActual.toString(),
          p.precioCompra.toStringAsFixed(2),
          (p.stockActual * p.precioCompra).toStringAsFixed(2),
        ]);
      }
    }

    return {'headers': headers, 'rows': rows};
  }

  Map<String, dynamic> _prepararDatosHistorial() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final headers = [
      'ID',
      'Fecha',
      'Tipo',
      'Cantidad',
      'Motivo',
      'Precio Unit.',
      'Total',
      'Factura',
      'Nota',
    ];

    final rows = _items.map((item) {
      final m = item as Movimiento;
      return [
        (m.id ?? '').toString(),
        dateFormat.format(m.fecha),
        m.tipo,
        m.cantidad.toString(),
        m.motivo ?? '',
        m.precioUnitario.toStringAsFixed(2),
        m.total.toStringAsFixed(2),
        m.numeroFactura ?? '',
        m.nota ?? '',
      ];
    }).toList();

    return {'headers': headers, 'rows': rows};
  }
}