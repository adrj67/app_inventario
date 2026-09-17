import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/producto_repository.dart';
import '../../../database/movimiento_repository.dart';
import '../../../database/categoria_repository.dart';
import '../../../database/proveedor_repository.dart';
import 'reporte_detalle_page.dart';

class ListadosPage extends StatefulWidget {
  const ListadosPage({super.key});

  @override
  State<ListadosPage> createState() => _ListadosPageState();
}

class _ListadosPageState extends State<ListadosPage> {
  final ProductoRepository _productoRepo = ProductoRepository();
  final MovimientoRepository _movimientoRepo = MovimientoRepository();
  final CategoriaRepository _categoriaRepo = CategoriaRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  bool _isLoading = true;

  // Estadísticas
  int _totalProductos = 0;
  int _totalCategorias = 0;
  int _totalProveedores = 0;
  int _totalMovimientos = 0;
  int _stockBajo = 0;
  int _agotados = 0;
  double _valorInventario = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productoRepo.getAll();
      final categorias = await _categoriaRepo.getAll();
      final proveedores = await _proveedorRepo.getAll();
      final movimientos = await _movimientoRepo.getAll();
      final stockBajo = await _productoRepo.getStockBajo();
      final agotados = await _productoRepo.getAgotados();
      final valor = await _productoRepo.getValorInventario();

      setState(() {
        _totalProductos = productos.length;
        _totalCategorias = categorias.length;
        _totalProveedores = proveedores.length;
        _totalMovimientos = movimientos.length;
        _stockBajo = stockBajo.length;
        _agotados = agotados.length;
        _valorInventario = valor;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildEstadisticasGenerales(),
            const SizedBox(height: 32),
            _buildTituloSeccion('Reportes de Inventario'),
            const SizedBox(height: 16),
            _buildReportesGrid(),
            const SizedBox(height: 32),
            _buildTituloSeccion('Exportar Datos'),
            const SizedBox(height: 16),
            _buildExportarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.analytics, color: Colors.deepPurple.shade700, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listados y Reportes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Visualizá y exportá la información de tu inventario',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadisticasGenerales() {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                titulo: 'Valor del Inventario',
                valor: currencyFormat.format(_valorInventario),
                icono: Icons.attach_money,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                titulo: 'Productos',
                valor: '$_totalProductos',
                icono: Icons.inventory_2,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                titulo: 'Categorías',
                valor: '$_totalCategorias',
                icono: Icons.category,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                titulo: 'Proveedores',
                valor: '$_totalProveedores',
                icono: Icons.business,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                titulo: 'Movimientos',
                valor: '$_totalMovimientos',
                icono: Icons.history,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                titulo: 'Stock Bajo',
                valor: '$_stockBajo',
                icono: Icons.warning_amber,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                titulo: 'Agotados',
                valor: '$_agotados',
                icono: Icons.remove_shopping_cart,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color.shade700, size: 24),
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
                    fontSize: 20,
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

  Widget _buildTituloSeccion(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildReportesGrid() {
    final reportes = [
      _ReporteData(
        titulo: 'Stock Bajo',
        descripcion: 'Productos que necesitan reposición',
        icono: Icons.warning_amber,
        color: Colors.orange,
        tipo: 'stock_bajo',
        contador: _stockBajo,
      ),
      _ReporteData(
        titulo: 'Productos Agotados',
        descripcion: 'Productos sin stock disponible',
        icono: Icons.remove_shopping_cart,
        color: Colors.red,
        tipo: 'agotados',
        contador: _agotados,
      ),
      _ReporteData(
        titulo: 'Top Más Movidos',
        descripcion: 'Productos con más movimientos',
        icono: Icons.trending_up,
        color: Colors.green,
        tipo: 'mas_movidos',
        contador: null,
      ),
      _ReporteData(
        titulo: 'Por Categoría',
        descripcion: 'Distribución del inventario',
        icono: Icons.pie_chart,
        color: Colors.purple,
        tipo: 'por_categoria',
        contador: _totalCategorias,
      ),
      _ReporteData(
        titulo: 'Por Proveedor',
        descripcion: 'Productos agrupados por proveedor',
        icono: Icons.business,
        color: Colors.teal,
        tipo: 'por_proveedor',
        contador: _totalProveedores,
      ),
      _ReporteData(
        titulo: 'Historial Completo',
        descripcion: 'Todos los movimientos registrados',
        icono: Icons.history,
        color: Colors.amber,
        tipo: 'historial',
        contador: _totalMovimientos,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.8,
      ),
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        return _buildReporteCard(reportes[index]);
      },
    );
  }

  Widget _buildReporteCard(_ReporteData reporte) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirReporte(reporte),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: reporte.color.shade100),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: reporte.color.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(reporte.icono, color: reporte.color.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reporte.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reporte.descripcion,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (reporte.contador != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: reporte.color.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reporte.contador}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: reporte.color.shade700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportarGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildExportarCard(
            titulo: 'Exportar Productos',
            descripcion: 'Todos los productos a CSV',
            icono: Icons.inventory_2,
            color: Colors.blue,
            onTap: () => _exportarProductos(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildExportarCard(
            titulo: 'Exportar Movimientos',
            descripcion: 'Historial completo a CSV',
            icono: Icons.history,
            color: Colors.amber,
            onTap: () => _exportarMovimientos(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildExportarCard(
            titulo: 'Stock Bajo',
            descripcion: 'Lista de reposición a CSV',
            icono: Icons.warning_amber,
            color: Colors.orange,
            onTap: () => _exportarStockBajo(),
          ),
        ),
      ],
    );
  }

  Widget _buildExportarCard({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.shade400, color.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: Colors.white, size: 28),
                  const Spacer(),
                  const Icon(Icons.download, color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirReporte(_ReporteData reporte) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReporteDetallePage(
          tipo: reporte.tipo,
          titulo: reporte.titulo,
          color: reporte.color,
        ),
      ),
    );
  }

  Future<void> _exportarProductos() async {
    // Por ahora mostramos un mensaje
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación a CSV en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _exportarMovimientos() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación a CSV en desarrollo'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Future<void> _exportarStockBajo() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación a CSV en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// ==================== CLASE AUXILIAR ====================

class _ReporteData {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final MaterialColor color;
  final String tipo;
  final int? contador;

  _ReporteData({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.tipo,
    this.contador,
  });
}