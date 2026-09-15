import '../models/ubicacion.dart';
import 'database_helper.dart';

class UbicacionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Ubicacion>> getAll({bool soloActivas = true}) async {
    final maps = await _db.query(
      'ubicaciones',
      where: soloActivas ? 'activo = 1' : null,
      orderBy: 'deposito ASC, pasillo ASC, estante ASC',
    );
    return maps.map((m) => Ubicacion.fromMap(m)).toList();
  }

  Future<List<Ubicacion>> search(String query) async {
    final maps = await _db.query(
      'ubicaciones',
      where: 'activo = 1 AND (deposito LIKE ? OR pasillo LIKE ? OR estante LIKE ? OR descripcion LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'deposito ASC',
    );
    return maps.map((m) => Ubicacion.fromMap(m)).toList();
  }

  Future<Ubicacion?> getById(int id) async {
    final maps = await _db.query(
      'ubicaciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Ubicacion.fromMap(maps.first);
  }

  Future<int> save(Ubicacion ubicacion) async {
    final data = ubicacion.toMap();
    if (ubicacion.id == null) {
      data.remove('id');
      return await _db.insert('ubicaciones', data);
    } else {
      data['id'] = ubicacion.id;
      return await _db.update('ubicaciones', data, id: ubicacion.id!);
    }
  }

  Future<int> delete(int id) async {
    final ubicacion = await getById(id);
    if (ubicacion == null) return 0;
    final updated = ubicacion.copyWith(activo: false);
    return await save(updated);
  }
}