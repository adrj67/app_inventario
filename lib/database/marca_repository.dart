import '../models/marca.dart';
import 'database_helper.dart';

class MarcaRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Marca>> getAll({bool soloActivas = true}) async {
    final maps = await _db.query(
      'marcas',
      where: soloActivas ? 'activa = 1' : null,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Marca.fromMap(m)).toList();
  }

  Future<List<Marca>> search(String query) async {
    final maps = await _db.query(
      'marcas',
      where: 'activa = 1 AND (nombre LIKE ? OR descripcion LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Marca.fromMap(m)).toList();
  }

  Future<Marca?> getById(int id) async {
    final maps = await _db.query(
      'marcas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Marca.fromMap(maps.first);
  }

  Future<int> save(Marca marca) async {
    final data = marca.toMap();
    if (marca.id == null) {
      data.remove('id');
      return await _db.insert('marcas', data);
    } else {
      data['id'] = marca.id;
      return await _db.update('marcas', data, id: marca.id!);
    }
  }

  Future<int> delete(int id) async {
    final marca = await getById(id);
    if (marca == null) return 0;
    final updated = marca.copyWith(activa: false);
    return await save(updated);
  }
}