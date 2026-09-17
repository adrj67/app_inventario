import '../models/cliente.dart';
import 'database_helper.dart';

class ClienteRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Cliente>> getAll({bool soloActivos = true}) async {
    final maps = await _db.query(
      'clientes',
      where: soloActivos ? 'activo = 1' : null,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<List<Cliente>> search(String query) async {
    final maps = await _db.query(
      'clientes',
      where: 'activo = 1 AND (nombre LIKE ? OR cuit LIKE ? OR telefono LIKE ? OR email LIKE ? OR localidad LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<Cliente?> getById(int id) async {
    final maps = await _db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Cliente.fromMap(maps.first);
  }

  Future<int> save(Cliente cliente) async {
    final data = cliente.toMap();
    if (cliente.id == null) {
      data.remove('id');
      return await _db.insert('clientes', data);
    } else {
      data['id'] = cliente.id;
      return await _db.update('clientes', data, id: cliente.id!);
    }
  }

  Future<int> delete(int id) async {
    final cliente = await getById(id);
    if (cliente == null) return 0;
    final updated = cliente.copyWith(activo: false);
    return await save(updated);
  }
}