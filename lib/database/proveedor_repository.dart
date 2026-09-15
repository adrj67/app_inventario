import '../models/proveedor.dart';
import 'database_helper.dart';

class ProveedorRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Proveedor>> getAll({bool soloActivos = true}) async {
    final maps = await _db.query(
      'proveedores',
      where: soloActivos ? 'activo = 1' : null,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Proveedor.fromMap(m)).toList();
  }

  Future<List<Proveedor>> search(String query) async {
    final maps = await _db.query(
      'proveedores',
      where: 'nombre LIKE ? OR cuit LIKE ? OR contacto LIKE ? OR telefono LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Proveedor.fromMap(m)).toList();
  }

  Future<Proveedor?> getById(int id) async {
    final maps = await _db.query(
      'proveedores',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Proveedor.fromMap(maps.first);
  }

  Future<int> save(Proveedor proveedor) async {
    final data = proveedor.toMap();

    if (proveedor.id == null) {
      data.remove('id');
      return await _db.insert('proveedores', data);
    } else {
      data['id'] = proveedor.id;
      return await _db.update('proveedores', data, id: proveedor.id!);
    }
  }

  Future<int> delete(int id) async {
    final proveedor = await getById(id);
    if (proveedor == null) return 0;

    final updated = proveedor.copyWith(
      nombre: proveedor.nombre,
      activo: false,
    );
    return await save(updated);
  }
}