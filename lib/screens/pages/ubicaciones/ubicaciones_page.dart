import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/ubicacion_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/ubicacion.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/export_button.dart';
import 'ubicacion_form.dart';
import '../productos/producto_form.dart';

class UbicacionesPage extends StatefulWidget {
  const UbicacionesPage({super.key});

  @override
  State<UbicacionesPage> createState() => _UbicacionesPageState();
}

class _UbicacionesPageState extends State<UbicacionesPage> {
  final UbicacionRepository _repository = UbicacionRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Ubicacion> _ubicaciones = [];
  List<Ubicacion> _filtered = [];
  Map<int, List<Producto>> _productosPorUbicacion = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUbicaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUbicaciones() async {
    setState(() => _isLoading = true);
    try {
      final ubicaciones = await _repository.getAll();
      final productos = await _productoRepository.getAll(soloActivos: false);

      // Agrupar productos por ubicacionId
      final Map<int, List<Producto>> agrupados = {};
      for (final p in productos) {
        if (p.ubicacionId != null) {
          agrupados.putIfAbsent(p.ubicacionId!, () => []).add(p);
        }
      }

      setState(() {
        _ubicaciones = ubicaciones;
        _filtered = ubicaciones;
        _productosPorUbicacion = agrupados;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _ubicaciones = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _ubicaciones);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _ubicaciones.where((u) {
        return u.deposito.toLowerCase().contains(q) ||
            (u.pasillo?.toLowerCase().contains(q) ?? false) ||
            (u.estante?.toLowerCase().contains(q) ?? false) ||
            (u.nivel?.toLowerCase().contains(q) ?? false) ||
            (u.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Ubicacion? ubicacion}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => UbicacionForm(ubicacion: ubicacion),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadUbicaciones();
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
      await _loadUbicaciones();
    }
  }

  Future<void> _confirmarEliminar(Ubicacion ubicacion) async {
    final productosAsociados = _productosPorUbicacion[ubicacion.id] ?? [];

    if (productosAsociados.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar "${ubicacion.nombreCompleto}": tiene ${productosAsociados.length} producto${productosAsociados.length > 1 ? "s" : ""} asociado${productosAsociados.length > 1 ? "s" : ""}',
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
            Text('Eliminar Ubicación'),
          ],
        ),
        content: Text('¿Eliminar "${ubicacion.nombreCompleto}"?'),
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
      await _repository.delete(ubicacion.id!);
      await _loadUbicaciones();
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
            hintText: 'Buscar por depósito, pasillo, estante...',
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final totalProductos = _productosPorUbicacion.values
        .fold<int>(0, (sum, list) => sum + list.length);

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
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Colors.indigo.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicaciones',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} ubicaciones · $totalProductos productos almacenados',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Ubicaciones',
                headers: const [
                  'ID', 'Depósito', 'Pasillo', 'Estante', 'Nivel',
                  'Descripción', 'Productos',
                ],
                rows: _filtered.map((u) => [
                  (u.id ?? '').toString(),
                  u.deposito,
                  u.pasillo ?? '',
                  u.estante ?? '',
                  u.nivel ?? '',
                  u.descripcion ?? '',
                  (_productosPorUbicacion[u.id]?.length ?? 0).toString(),
                ]).toList(),
                color: Colors.indigo,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Ubicación',
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
            Icon(Icons.location_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay ubicaciones'
                  : 'Sin resultados',
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

    // Agrupar ubicaciones por depósito
    final Map<String, List<Ubicacion>> porDeposito = {};
    for (final u in _filtered) {
      porDeposito.putIfAbsent(u.deposito, () => []).add(u);
    }

    final depositos = porDeposito.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: depositos.length,
      itemBuilder: (context, index) {
        final deposito = depositos[index];
        final ubicacionesDelDeposito = porDeposito[deposito]!;

        return _DepositoGrupo(
          deposito: deposito,
          ubicaciones: ubicacionesDelDeposito,
          productosPorUbicacion: _productosPorUbicacion,
          onEdit: (u) => _abrirFormulario(ubicacion: u),
          onDelete: _confirmarEliminar,
          onProductoTap: _editarProducto,
        );
      },
    );
  }
}

// ==================== GRUPO DE DEPÓSITO ====================

class _DepositoGrupo extends StatelessWidget {
  final String deposito;
  final List<Ubicacion> ubicaciones;
  final Map<int, List<Producto>> productosPorUbicacion;
  final Function(Ubicacion) onEdit;
  final Function(Ubicacion) onDelete;
  final Function(Producto) onProductoTap;

  const _DepositoGrupo({
    required this.deposito,
    required this.ubicaciones,
    required this.productosPorUbicacion,
    required this.onEdit,
    required this.onDelete,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    // Contar productos totales del depósito
    final totalProductos = ubicaciones.fold<int>(
      0,
      (sum, u) => sum + (productosPorUbicacion[u.id]?.length ?? 0),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: true,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.warehouse, color: Colors.indigo.shade700),
        ),
        title: Text(
          deposito,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${ubicaciones.length} ubicación${ubicaciones.length != 1 ? "es" : ""}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: totalProductos > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$totalProductos prod.',
                style: TextStyle(
                  fontSize: 11,
                  color: totalProductos > 0
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          ...ubicaciones.map((u) {
            final productos = productosPorUbicacion[u.id] ?? [];
            return _UbicacionItem(
              ubicacion: u,
              productos: productos,
              onEdit: () => onEdit(u),
              onDelete: () => onDelete(u),
              onProductoTap: onProductoTap,
            );
          }),
        ],
      ),
    );
  }
}

// ==================== ITEM DE UBICACIÓN ====================

class _UbicacionItem extends StatelessWidget {
  final Ubicacion ubicacion;
  final List<Producto> productos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Producto) onProductoTap;

  const _UbicacionItem({
    required this.ubicacion,
    required this.productos,
    required this.onEdit,
    required this.onDelete,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          Icons.location_on,
          color: Colors.indigo.shade400,
          size: 20,
        ),
        title: Text(
          _buildNombreCorto(),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ubicacion.descripcion != null)
              Text(
                ubicacion.descripcion!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 2),
            Text(
              '${productos.length} producto${productos.length != 1 ? "s" : ""}',
              style: TextStyle(
                fontSize: 11,
                color: productos.isEmpty ? Colors.grey.shade500 : Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              onPressed: onEdit,
              tooltip: 'Editar ubicación',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: onDelete,
              tooltip: 'Eliminar ubicación',
            ),
          ],
        ),
        children: [
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sin productos en esta ubicación',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else ...[
            // Encabezados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            ...productos.map((p) => _buildItemProducto(p)),
          ],
        ],
      ),
    );
  }

  /// Devuelve el nombre de la ubicación sin el depósito (ya está en el grupo)
  String _buildNombreCorto() {
    final parts = <String>[];
    if (ubicacion.pasillo != null && ubicacion.pasillo!.isNotEmpty) {
      parts.add('Pasillo ${ubicacion.pasillo}');
    }
    if (ubicacion.estante != null && ubicacion.estante!.isNotEmpty) {
      parts.add('Estante ${ubicacion.estante}');
    }
    if (ubicacion.nivel != null && ubicacion.nivel!.isNotEmpty) {
      parts.add('Nivel ${ubicacion.nivel}');
    }
    if (parts.isEmpty) return 'Ubicación general';
    return parts.join(' · ');
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

  Widget _buildItemProducto(Producto p) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => onProductoTap(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
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
                  fontSize: 12,
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
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}