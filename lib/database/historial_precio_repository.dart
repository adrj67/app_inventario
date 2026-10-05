import '../models/historial_precio.dart';
import 'database_helper.dart';

class HistorialPrecioRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Obtiene el historial de un producto (ordenado por fecha desc)
  Future<List<HistorialPrecio>> getByProducto(int productoId) async {
    final maps = await _db.query(
      'historial_precios',
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => HistorialPrecio.fromMap(m)).toList();
  }

  /// Registra un cambio de precio
  Future<int> registrar(HistorialPrecio historial) async {
    final data = historial.toMap();
    data.remove('id');
    return await _db.insert('historial_precios', data);
  }

  /// Obtiene el último registro de un producto (para comparar)
  Future<HistorialPrecio?> getUltimo(int productoId) async {
    final maps = await _db.query(
      'historial_precios',
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
    if (maps.isEmpty) return null;
    return HistorialPrecio.fromMap(maps.first);
  }

  /// Elimina todo el historial de un producto (al eliminar el producto)
  Future<int> deleteByProducto(int productoId) async {
    final db = await _db.database;
    return await db.delete(
      'historial_precios',
      where: 'productoId = ?',
      whereArgs: [productoId],
    );
  }
}