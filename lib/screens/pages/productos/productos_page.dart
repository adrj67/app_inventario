import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/producto_repository.dart';
import '../../../models/producto.dart';
import '../../../widgets/search_field.dart';
import 'producto_form.dart';
import '../../../widgets/export_button.dart';
import '../../../database/marca_repository.dart';
import '../../../models/marca.dart';
import '../../../database/categoria_repository.dart';
import '../../../models/categoria.dart';
import '../../../database/ubicacion_repository.dart';
import '../../../models/ubicacion.dart';
import 'package:provider/provider.dart';
import '../../../controllers/productos_filter_controller.dart';

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
  // Filtro Marcas
  final MarcaRepository _marcaRepository = MarcaRepository();
  List<Marca> _marcas = [];
  int? _filtroMarcaId;
  // Filtro Categorias
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  List<Categoria> _categorias = [];
  int? _filtroCategoriaId;
  // Filtro por ubicación
  final UbicacionRepository _ubicacionRepository = UbicacionRepository();
  List<Ubicacion> _ubicaciones = [];
  int? _filtroUbicacionId;

  @override
  void initState() {
    super.initState();
    _cargarMarcas();
    _cargarCategorias();
    _cargarUbicaciones(); 
    _loadProductos();

    // 🔥 Escuchar cambios del controller de filtros
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<ProductosFilterController>();
      controller.addListener(_onFiltroExternoAplicado);

      // Aplicar filtro inicial si ya hay uno
      _aplicarFiltroExterno(controller);
    });
  }

  void _onFiltroExternoAplicado() {
    if (!mounted) return;
    final controller = context.read<ProductosFilterController>();
    _aplicarFiltroExterno(controller);
  }

  void _aplicarFiltroExterno(ProductosFilterController controller) {
    setState(() {
      _filtroCategoriaId = controller.categoriaId;
      _filtroMarcaId = controller.marcaId;
      _filtroUbicacionId = controller.ubicacionId;
      _filtroEstado = controller.estado;
    });
    _aplicarFiltros();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // 🔥 Quitar el listener
    try {
      context.read<ProductosFilterController>().removeListener(_onFiltroExternoAplicado);
    } catch (_) {}
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

    // Filtro por marca
    if (_filtroMarcaId != null) {
      resultado = resultado.where((p) => p.marcaId == _filtroMarcaId).toList();
    }

    // Filtro por categoría
    if (_filtroCategoriaId != null) {
      final idsDescendientes = _obtenerIdsDescendientes(_filtroCategoriaId!);
      resultado = resultado
          .where((p) => p.categoriaId != null && idsDescendientes.contains(p.categoriaId))
          .toList();
    }

    // 🔥 NUEVO: Filtro por ubicación
    if (_filtroUbicacionId != null) {
      resultado = resultado.where((p) => p.ubicacionId == _filtroUbicacionId).toList();
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

  Future<void> _duplicarProducto(Producto original) async {
    // Crear una copia del producto con los campos únicos limpios
    final copia = original.copyWith(
      id: null,                                          // Nuevo ID
      sku: '',                                           // SKU debe ser único
      codigoBarras: '',                                  // Código debe ser único
      nombre: '${original.nombre} (copia)',              // Identificar
      stockActual: 0,                                    // Producto nuevo
      fechaCompra: DateTime.now(),                       // Fecha actual
      fechaCreacion: DateTime.now(),
      fechaUltimaModificacion: DateTime.now(),
      //fechaVenta: null,
      //numeroFacturaVenta: null,
      // El resto se mantiene igual
    );

    // Abrir el formulario con los datos precargados
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ProductoForm(
          producto: copia,
          esDuplicado: true,   // 🔥 Marca como duplicado para que no lo trate como edición
        ),
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

  Future<void> _cargarMarcas() async {
    try {
      final marcas = await _marcaRepository.getAll();
      setState(() => _marcas = marcas);
    } catch (e) {
      debugPrint('Error cargando marcas: $e');
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await _categoriaRepository.getAll();
      setState(() => _categorias = categorias);
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  Future<void> _cargarUbicaciones() async {
    try {
      final ubicaciones = await _ubicacionRepository.getAll();
      setState(() => _ubicaciones = ubicaciones);
    } catch (e) {
      debugPrint('Error cargando ubicaciones: $e');
    }
  }

  /// Devuelve el nombre de la categoría con su padre (si lo tiene)
  String _nombreCategoriaCompleto(Categoria cat) {
    if (cat.categoriaPadreId == null) {
      return cat.nombre;
    }
    final padre = _categorias
        .where((c) => c.id == cat.categoriaPadreId)
        .firstOrNull;
    if (padre != null) {
      return '${padre.nombre} > ${cat.nombre}';
    }
    return cat.nombre;
  }

    /// Devuelve los IDs de una categoría + todos sus descendientes (subcategorías)
  Set<int> _obtenerIdsDescendientes(int categoriaRaizId) {
    final ids = <int>{categoriaRaizId};

    // Búsqueda recursiva de descendientes
    void buscarHijos(int padreId) {
      final hijos = _categorias.where((c) => c.categoriaPadreId == padreId);
      for (final hijo in hijos) {
        if (hijo.id != null && !ids.contains(hijo.id)) {
          ids.add(hijo.id!);
          buscarHijos(hijo.id!); // Recursión
        }
      }
    }

    buscarHijos(categoriaRaizId);
    return ids;
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
          Row(
            children: [
              ExportButton(
                titulo: 'Productos',
                headers: const [
                  'ID',
                  'SKU',
                  'Nombre',
                  'Modelo',
                  'Marca',
                  'Categoría',
                  'Depósito',
                  'Stock',
                  'Precio Compra',
                  'Estado',
                ],
                rows: _filtered.map((p) {
                  final marca = _marcas.where((m) => m.id == p.marcaId).firstOrNull;
                  final categoria = _categorias.where((c) => c.id == p.categoriaId).firstOrNull;
                  final ubicacion = _ubicaciones.where((u) => u.id == p.ubicacionId).firstOrNull;

                  return [
                    (p.id ?? '').toString(),
                    p.sku,
                    p.nombre,
                    p.modelo ?? '',
                    marca?.nombre ?? '',
                    categoria != null ? _nombreCategoriaCompleto(categoria) : '',
                    ubicacion?.nombreCompleto ?? '',
                    p.stockActual.toString(),
                    p.precioCompra.toStringAsFixed(2),
                    p.estaAgotado
                        ? 'Agotado'
                        : (p.tieneStockBajo ? 'Stock Bajo' : 'En Stock'),
                  ];
                }).toList(),
                color: Colors.blue,
                leyendaFiltros: _construirLeyendaFiltros(),  // 🔥 NUEVO
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono más chico
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icono, color: color.shade700, size: 16),
          ),
          const SizedBox(width: 8),
          // Textos más compactos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 15,
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
    final hayFiltrosActivos = _filtroEstado != 'todos' ||
        _filtroMarcaId != null ||
        _filtroCategoriaId != null ||
        _filtroUbicacionId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 🔥 Si el ancho es menor a 900px, apilamos los dropdowns
          final esAngosto = constraints.maxWidth < 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== FILA 1: ESTADOS + LIMPIAR ====================
              Row(
                children: [
                  // Chips con scroll horizontal si no entran
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Todos', 'todos', Icons.list),
                          const SizedBox(width: 8),
                          _buildFilterChip('Stock Bajo', 'stock_bajo', Icons.warning_amber),
                          const SizedBox(width: 8),
                          _buildFilterChip('Agotados', 'agotados', Icons.remove_shopping_cart),
                        ],
                      ),
                    ),
                  ),

                  // Botón limpiar filtros (solo si hay filtros activos)
                  if (hayFiltrosActivos) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _filtroEstado = 'todos';
                          _filtroMarcaId = null;
                          _filtroCategoriaId = null;
                          _filtroUbicacionId = null;
                          _searchController.clear();
                        });
                        _aplicarFiltros();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // ==================== FILA 2: DROPDOWNS ====================
              if (esAngosto) ...[
                // 🔥 Layout vertical para pantallas angostas
                _buildDropdownCategoria(),
                const SizedBox(height: 8),
                _buildDropdownMarca(),
                const SizedBox(height: 8),
                _buildDropdownUbicacion(),
              ] else ...[
                // 🔥 Layout horizontal para pantallas anchas
                Row(
                  children: [
                    Expanded(child: _buildDropdownCategoria()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownMarca()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownUbicacion()),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // 🔥 Dropdown de Categoría
  Widget _buildDropdownCategoria() {
    final seleccionada = _filtroCategoriaId != null;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: seleccionada ? Colors.purple.shade700 : Colors.grey.shade300,
          width: seleccionada ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _filtroCategoriaId,
          isExpanded: true,
          isDense: true,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Categorías',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: seleccionada ? Colors.purple.shade700 : Colors.grey.shade600,
          ),
          style: TextStyle(
            fontSize: 13,
            color: seleccionada ? Colors.purple.shade700 : Colors.grey.shade700,
            fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w500,
          ),
          selectedItemBuilder: (context) {
            return [
              // Opción "Todas"
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.purple.shade700),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Todas las categorías',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Opciones de categorías
              ..._categorias.map((c) => Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.purple.shade700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _nombreCategoriaCompleto(c),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ];
          },
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las categorías'),
            ),
            ..._categorias.map((c) => DropdownMenuItem<int?>(
                  value: c.id,
                  child: Text(
                    _nombreCategoriaCompleto(c),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) {
            setState(() => _filtroCategoriaId = v);
            _aplicarFiltros();
          },
        ),
      ),
    );
  }

  // 🔥 Dropdown de Marca
  Widget _buildDropdownMarca() {
    final seleccionada = _filtroMarcaId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: seleccionada ? Colors.teal.shade700 : Colors.grey.shade300,
          width: seleccionada ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _filtroMarcaId,
          isExpanded: true,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_offer, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Todas las marcas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: seleccionada ? Colors.teal.shade700 : Colors.grey.shade600,
          ),
          style: TextStyle(
            fontSize: 13,
            color: seleccionada ? Colors.teal.shade700 : Colors.grey.shade700,
            fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w500,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las marcas'),
            ),
            ..._marcas.map((m) => DropdownMenuItem<int?>(
                  value: m.id,
                  child: Text(
                    m.nombre,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) {
            setState(() => _filtroMarcaId = v);
            _aplicarFiltros();
          },
        ),
      ),
    );
  }

  // 🔥 Dropdown de Ubicación
  Widget _buildDropdownUbicacion() {
    final seleccionada = _filtroUbicacionId != null;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: seleccionada ? Colors.indigo.shade700 : Colors.grey.shade300,
          width: seleccionada ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _filtroUbicacionId,
          isExpanded: true,
          isDense: true,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Ubicaciones',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: seleccionada ? Colors.indigo.shade700 : Colors.grey.shade600,
          ),
          style: TextStyle(
            fontSize: 13,
            color: seleccionada ? Colors.indigo.shade700 : Colors.grey.shade700,
            fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w500,
          ),
          selectedItemBuilder: (context) {
            return [
              // Opción "Todas"
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.indigo.shade700),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Todas las ubicaciones',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Opciones de ubicaciones
              ..._ubicaciones.map((u) => Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.indigo.shade700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            u.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ];
          },
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las ubicaciones'),
            ),
            ..._ubicaciones.map((u) => DropdownMenuItem<int?>(
                  value: u.id,
                  child: Text(
                    u.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) {
            setState(() => _filtroUbicacionId = v);
            _aplicarFiltros();
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filtroEstado == value;

    return Material(
      color: isSelected ? Colors.blue.shade700 : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          setState(() => _filtroEstado = value);
          _aplicarFiltros();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
            onDuplicar: () => _duplicarProducto(producto),
          );
        },
      ),
    );
  }

  /// Construye el texto con los filtros aplicados
  String? _construirLeyendaFiltros() {
    final filtros = <String>[];

    // Estado
    if (_filtroEstado != 'todos') {
      final estadoTexto = _filtroEstado == 'stock_bajo'
          ? 'Stock Bajo'
          : 'Agotados';
      filtros.add('Estado: $estadoTexto');
    }

    // Categoría
    if (_filtroCategoriaId != null) {
      final cat = _categorias.where((c) => c.id == _filtroCategoriaId).firstOrNull;
      filtros.add('Categoría: ${cat != null ? _nombreCategoriaCompleto(cat) : "?"}');
    }

    // Marca
    if (_filtroMarcaId != null) {
      final marca = _marcas.where((m) => m.id == _filtroMarcaId).firstOrNull;
      filtros.add('Marca: ${marca?.nombre ?? "?"}');
    }

    // Ubicación
    if (_filtroUbicacionId != null) {
      final ubic = _ubicaciones.where((u) => u.id == _filtroUbicacionId).firstOrNull;
      filtros.add('Ubicación: ${ubic?.nombreCompleto ?? "?"}');
    }

    // Búsqueda
    final busqueda = _searchController.text.trim();
    if (busqueda.isNotEmpty) {
      filtros.add('Búsqueda: "$busqueda"');
    }

    // Si no hay filtros, devolver null
    if (filtros.isEmpty) return null;

    return 'Filtros aplicados: ${filtros.join("  |  ")}';
  }
}

// ==================== WIDGET CARD ====================

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicar;

  const _ProductoCard({
    required this.producto,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicar,
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

              // 🔥 Botón Duplicar
              IconButton(
                icon: const Icon(Icons.copy_outlined, color: Colors.blue),
                onPressed: onDuplicar,
                tooltip: 'Duplicar producto',
              ),
              // Botón Eliminar
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