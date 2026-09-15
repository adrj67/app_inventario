import '../models/categoria.dart';
import 'database_helper.dart';

class CategoriaRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Categoria>> getAll({bool soloActivas = true}) async {
    final maps = await _db.query(
      'categorias',
      where: soloActivas ? 'activa = 1' : null,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<List<Categoria>> getRaices() async {
    final maps = await _db.query(
      'categorias',
      where: 'activa = 1 AND categoriaPadreId IS NULL',
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<List<Categoria>> getHijos(int padreId) async {
    final maps = await _db.query(
      'categorias',
      where: 'activa = 1 AND categoriaPadreId = ?',
      whereArgs: [padreId],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<List<Categoria>> search(String query) async {
    final maps = await _db.query(
      'categorias',
      where: 'activa = 1 AND (nombre LIKE ? OR descripcion LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<Categoria?> getById(int id) async {
    final maps = await _db.query(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Categoria.fromMap(maps.first);
  }

  Future<int> save(Categoria categoria) async {
    final data = categoria.toMap();

    if (categoria.id == null) {
      data.remove('id');
      return await _db.insert('categorias', data);
    } else {
      data['id'] = categoria.id;
      return await _db.update('categorias', data, id: categoria.id!);
    }
  }

  Future<int> delete(int id) async {
    // Verificar que no tenga subcategorías
    final hijos = await getHijos(id);
    if (hijos.isNotEmpty) {
      throw Exception('No se puede eliminar: tiene subcategorías asociadas');
    }

    final categoria = await getById(id);
    if (categoria == null) return 0;

    final updated = categoria.copyWith(activa: false);
    return await save(updated);
  }
}