import '../models/movimiento.dart';
import '../models/producto.dart';
import 'database_helper.dart';

class MovimientoRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ==================== LEER ====================

  Future<List<Movimiento>> getAll() async {
    final maps = await _db.query(
      'movimientos',
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }

  Future<List<Movimiento>> getByProducto(int productoId) async {
    final maps = await _db.query(
      'movimientos',
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }

  Future<List<Movimiento>> getByTipo(String tipo) async {
    final maps = await _db.query(
      'movimientos',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }

  Future<Movimiento?> getById(int id) async {
    final maps = await _db.query(
      'movimientos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Movimiento.fromMap(maps.first);
  }

  Future<List<Movimiento>> search(String query) async {
    final maps = await _db.query(
      'movimientos',
      where: 'motivo LIKE ? OR nota LIKE ? OR numeroFactura LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }

  // ==================== GUARDAR CON TRANSACCIÓN ====================

  /// Guarda un movimiento y actualiza el stock del producto.
  /// Todo se hace en una transacción: si algo falla, se revierte.
  Future<int> save(Movimiento movimiento) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      // 1. Obtener el producto actual
      final productosMaps = await txn.query(
        'productos',
        where: 'id = ?',
        whereArgs: [movimiento.productoId],
      );

      if (productosMaps.isEmpty) {
        throw Exception('Producto no encontrado');
      }

      final producto = Producto.fromMap(productosMaps.first);

      // 2. Calcular nuevo stock según el tipo de movimiento
      int nuevoStock;
      if (movimiento.tipo == 'salida') {
        nuevoStock = producto.stockActual - movimiento.cantidad;
        if (nuevoStock < 0) {
          throw Exception(
            'No hay suficiente stock. Disponible: ${producto.stockActual}',
          );
        }
      } else {
        // entrada
        nuevoStock = producto.stockActual + movimiento.cantidad;
      }

      // 3. Determinar nuevo estado
      String nuevoEstado;
      if (nuevoStock <= 0) {
        nuevoEstado = 'agotado';
      } else if (nuevoStock <= producto.stockMinimo) {
        nuevoEstado = 'stock_bajo';
      } else {
        nuevoEstado = 'en_stock';
      }

      // 4. Insertar el movimiento
      final movimientoData = movimiento.toMap();
      if (movimiento.id == null) {
        movimientoData.remove('id');
      }
      final movimientoId = await txn.insert('movimientos', movimientoData);

      // 5. Actualizar el producto
      final productoData = producto.toMap();
      productoData['stockActual'] = nuevoStock;
      productoData['estado'] = nuevoEstado;
      productoData['estaDisponible'] = nuevoStock > 0 ? 1 : 0;
      productoData['fechaUltimaModificacion'] = DateTime.now().toIso8601String();

      await txn.update(
        'productos',
        productoData,
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      return movimientoId;
    });
  }

  // ==================== ESTADÍSTICAS ====================

  Future<int> countMovimientos() async {
    final maps = await _db.query('movimientos');
    return maps.length;
  }

  Future<List<Movimiento>> getUltimos({int limit = 10}) async {
    final db = await _db.database;
    final maps = await db.query(
      'movimientos',
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }
}