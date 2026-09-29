import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/categoria_repository.dart';
import '../../../database/producto_repository.dart';
import '../../../models/categoria.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/export_button.dart';
import 'categoria_form.dart';
import '../productos/producto_form.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final CategoriaRepository _repository = CategoriaRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Categoria> _filtered = [];
  Map<int, List<Producto>> _productosPorCategoria = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _repository.getAll();
      final productos = await _productoRepository.getAll(soloActivos: false);

      // Agrupar productos por categoriaId
      final Map<int, List<Producto>> agrupados = {};
      for (final p in productos) {
        if (p.categoriaId != null) {
          agrupados.putIfAbsent(p.categoriaId!, () => []).add(p);
        }
      }

      setState(() {
        _categorias = categorias;
        _filtered = categorias;
        _productosPorCategoria = agrupados;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _categorias = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _categorias);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _categorias.where((c) {
        return c.nombre.toLowerCase().contains(q) ||
            (c.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Categoria? categoria, int? categoriaPadreId}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CategoriaForm(
          categoria: categoria,
          categoriaPadreIdPredefinido: categoriaPadreId,
        ),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadCategorias();
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
      await _loadCategorias();
    }
  }

  Future<void> _confirmarEliminar(Categoria categoria) async {
    final hijos = _categorias.where((c) => c.categoriaPadreId == categoria.id).toList();
    final productosAsociados = _productosPorCategoria[categoria.id] ?? [];

    // Validación 1: tiene subcategorías
    if (hijos.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar "${categoria.nombre}": tiene ${hijos.length} subcategoría${hijos.length > 1 ? "s" : ""}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validación 2: tiene productos asociados
    if (productosAsociados.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar "${categoria.nombre}": tiene ${productosAsociados.length} producto${productosAsociados.length > 1 ? "s" : ""} asociado${productosAsociados.length > 1 ? "s" : ""}',
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
            Text('Eliminar Categoría'),
          ],
        ),
        content: Text('¿Eliminar "${categoria.nombre}"?'),
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
      await _repository.delete(categoria.id!);
      await _loadCategorias();
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
            hintText: 'Buscar categorías...',
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final totalProductos = _productosPorCategoria.values
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
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category, color: Colors.purple.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} categorías · $totalProductos productos',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Categorías',
                headers: const [
                  'ID', 'Nombre', 'Descripción', 'Categoría Padre',
                  'Productos', 'Estado',
                ],
                rows: _filtered.map((c) {
                  final padre = _categorias
                      .where((x) => x.id == c.categoriaPadreId)
                      .firstOrNull;
                  return [
                    (c.id ?? '').toString(),
                    c.nombre,
                    c.descripcion ?? '',
                    padre?.nombre ?? '(raíz)',
                    (_productosPorCategoria[c.id]?.length ?? 0).toString(),
                    c.activa ? 'Activa' : 'Inactiva',
                  ];
                }).toList(),
                color: Colors.purple,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Categoría',
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
            Icon(Icons.category_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay categorías'
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

    // Mostrar solo las raíces
    final raices = _filtered.where((c) => c.categoriaPadreId == null).toList();

    // Si la búsqueda da resultados que NO son raíces, mostrarlos también
    final noMostrados = _filtered
        .where((c) => c.categoriaPadreId != null)
        .where((c) => !raices.any((r) => r.id == c.categoriaPadreId))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: raices.length + noMostrados.length,
      itemBuilder: (context, index) {
        if (index < raices.length) {
          final raiz = raices[index];
          final hijos = _categorias
              .where((c) => c.categoriaPadreId == raiz.id)
              .toList();
          return _CategoriaRaizCard(
            categoria: raiz,
            subcategorias: hijos,
            productosPorCategoria: _productosPorCategoria,
            onEdit: () => _abrirFormulario(categoria: raiz),
            onDelete: () => _confirmarEliminar(raiz),
            onSubEdit: (sub) => _abrirFormulario(categoria: sub),
            onSubDelete: (sub) => _confirmarEliminar(sub),
            onAgregarSub: () => _abrirFormulario(categoriaPadreId: raiz.id),
            onProductoTap: _editarProducto,
          );
        } else {
          // Mostrar categorías huérfanas (sin padre visible)
          final cat = noMostrados[index - raices.length];
          return _CategoriaHuerfanaCard(
            categoria: cat,
            productos: _productosPorCategoria[cat.id] ?? [],
            onEdit: () => _abrirFormulario(categoria: cat),
            onDelete: () => _confirmarEliminar(cat),
            onProductoTap: _editarProducto,
          );
        }
      },
    );
  }
}

// ==================== CARD DE CATEGORÍA RAÍZ ====================

class _CategoriaRaizCard extends StatelessWidget {
  final Categoria categoria;
  final List<Categoria> subcategorias;
  final Map<int, List<Producto>> productosPorCategoria;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Categoria) onSubEdit;
  final Function(Categoria) onSubDelete;
  final VoidCallback onAgregarSub;
  final Function(Producto) onProductoTap;

  const _CategoriaRaizCard({
    required this.categoria,
    required this.subcategorias,
    required this.productosPorCategoria,
    required this.onEdit,
    required this.onDelete,
    required this.onSubEdit,
    required this.onSubDelete,
    required this.onAgregarSub,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    // Contar productos totales (de la raíz + todas las subcategorías)
    final productosRaiz = productosPorCategoria[categoria.id] ?? [];
    final productosSub = subcategorias.fold<int>(
      0,
      (sum, sub) => sum + (productosPorCategoria[sub.id]?.length ?? 0),
    );
    final totalProductos = productosRaiz.length + productosSub;

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
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder, color: Colors.purple.shade700),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoria.descripcion != null)
              Text(
                categoria.descripcion!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                _buildBadge(
                  '${subcategorias.length} sub',
                  Colors.purple.shade50,
                  Colors.purple.shade700,
                ),
                const SizedBox(width: 6),
                _buildBadge(
                  '$totalProductos prod.',
                  totalProductos > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                  totalProductos > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                ),
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
              tooltip: 'Editar categoría',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: onDelete,
              tooltip: 'Eliminar categoría',
            ),
          ],
        ),
        children: [
          // Productos directos de la raíz
          if (productosRaiz.isNotEmpty) ...[
            _buildSubHeader('Productos sin subcategoría'),
            ...productosRaiz.map((p) => _buildItemProducto(context, p)),
          ],

          // Subcategorías
          ...subcategorias.map((sub) {
            final productosSub = productosPorCategoria[sub.id] ?? [];
            return _SubcategoriaExpansion(
              subcategoria: sub,
              productos: productosSub,
              onEdit: () => onSubEdit(sub),
              onDelete: () => onSubDelete(sub),
              onProductoTap: onProductoTap,
            );
          }),

          // Si no hay nada
          if (productosRaiz.isEmpty && subcategorias.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría vacía',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Botón agregar subcategoría
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onAgregarSub,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar subcategoría'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade100,
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
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
            Icon(Icons.inventory_2, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ==================== SUBCATEGORÍA EXPANSIBLE ====================

class _SubcategoriaExpansion extends StatelessWidget {
  final Categoria subcategoria;
  final List<Producto> productos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Producto) onProductoTap;

  const _SubcategoriaExpansion({
    required this.subcategoria,
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
          Icons.subdirectory_arrow_right,
          color: Colors.purple.shade400,
          size: 20,
        ),
        title: Text(
          subcategoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${productos.length} producto${productos.length != 1 ? "s" : ""}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              onPressed: onEdit,
              tooltip: 'Editar subcategoría',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: onDelete,
              tooltip: 'Eliminar subcategoría',
            ),
          ],
        ),
        children: [
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sin productos en esta subcategoría',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            ...productos.map((p) => _buildItemProducto(context, p)),
        ],
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

// ==================== CARD DE CATEGORÍA HUÉRFANA ====================

class _CategoriaHuerfanaCard extends StatelessWidget {
  final Categoria categoria;
  final List<Producto> productos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Producto) onProductoTap;

  const _CategoriaHuerfanaCard({
    required this.categoria,
    required this.productos,
    required this.onEdit,
    required this.onDelete,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder, color: Colors.purple.shade700),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '${productos.length} producto${productos.length != 1 ? "s" : ""}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}