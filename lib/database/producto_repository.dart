import '../models/producto.dart';
import 'database_helper.dart';

class ProductoRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ==================== LEER ====================

  /// Obtener todos los productos
  Future<List<Producto>> getAll({bool soloActivos = true}) async {
    final maps = await _db.query(
      'productos',
      where: soloActivos ? 'estaActivo = 1' : null,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Buscar por nombre, SKU, código de barras o modelo
  Future<List<Producto>> search(String query) async {
    final maps = await _db.query(
      'productos',
      where: 'estaActivo = 1 AND (nombre LIKE ? OR sku LIKE ? OR codigoBarras LIKE ? OR modelo LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Obtener por ID
  Future<Producto?> getById(int id) async {
    final maps = await _db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  /// Productos con stock bajo (stockActual <= stockMinimo)
  Future<List<Producto>> getStockBajo() async {
    final maps = await _db.query(
      'productos',
      where: 'estaActivo = 1 AND stockActual <= stockMinimo AND stockActual > 0',
      orderBy: 'stockActual ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Productos agotados (stockActual <= 0)
  Future<List<Producto>> getAgotados() async {
    final maps = await _db.query(
      'productos',
      where: 'estaActivo = 1 AND stockActual <= 0',
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Productos por proveedor
  Future<List<Producto>> getByProveedor(int proveedorId) async {
    final maps = await _db.query(
      'productos',
      where: 'estaActivo = 1 AND proveedorId = ?',
      whereArgs: [proveedorId],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Productos por categoría
  Future<List<Producto>> getByCategoria(int categoriaId) async {
    final maps = await _db.query(
      'productos',
      where: 'estaActivo = 1 AND categoriaId = ?',
      whereArgs: [categoriaId],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  // ==================== GUARDAR ====================

  /// Crear o actualizar producto
  Future<int> save(Producto producto) async {
    final data = producto.toMap();

    if (producto.id == null) {
      data.remove('id');
      return await _db.insert('productos', data);
    } else {
      data['id'] = producto.id;
      data['fechaUltimaModificacion'] = DateTime.now().toIso8601String();
      return await _db.update('productos', data, id: producto.id!);
    }
  }

  // ==================== ELIMINAR ====================

  /// Eliminación lógica (marca estaActivo = 0)
  Future<int> delete(int id) async {
    final producto = await getById(id);
    if (producto == null) return 0;

    final updated = producto.copyWith(estaActivo: false);
    return await save(updated);
  }

  // ==================== OPERACIONES DE STOCK ====================

  /// Ajustar stock (positivo = entrada, negativo = salida)
  Future<int> ajustarStock(int productoId, int cantidad) async {
    final producto = await getById(productoId);
    if (producto == null) return 0;

    final nuevoStock = producto.stockActual + cantidad;
    if (nuevoStock < 0) {
      throw Exception('No hay suficiente stock disponible');
    }

    // Determinar nuevo estado
    String nuevoEstado;
    if (nuevoStock <= 0) {
      nuevoEstado = 'agotado';
    } else if (nuevoStock <= producto.stockMinimo) {
      nuevoEstado = 'stock_bajo';
    } else {
      nuevoEstado = 'en_stock';
    }

    final updated = producto.copyWith(
      stockActual: nuevoStock,
      estado: nuevoEstado,
      estaDisponible: nuevoStock > 0,
    );

    return await save(updated);
  }

  // ==================== ESTADÍSTICAS ====================

  /// Contar productos activos
  Future<int> countActivos() async {
    final productos = await getAll(soloActivos: true);
    return productos.length;
  }

  /// Valor total del inventario (stock * precioCompra)
  Future<double> getValorInventario() async {
    final productos = await getAll(soloActivos: true);
    double total = 0;
    for (final p in productos) {
      total += p.stockActual * p.precioCompra;
    }
    return total;
  }

  /// Cantidad de productos con stock bajo
  Future<int> countStockBajo() async {
    final productos = await getStockBajo();
    return productos.length;
  }

  /// Cantidad de productos agotados
  Future<int> countAgotados() async {
    final productos = await getAgotados();
    return productos.length;
  }
}