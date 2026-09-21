import '../models/presupuesto.dart';
import '../models/presupuesto_item.dart';
import 'database_helper.dart';

class PresupuestoRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ==================== LEER ====================

  Future<List<Presupuesto>> getAll() async {
    final maps = await _db.query('presupuestos', orderBy: 'fecha DESC, id DESC');
    return maps.map((m) => Presupuesto.fromMap(m)).toList();
  }

  Future<List<Presupuesto>> getByEstado(String estado) async {
    final maps = await _db.query(
      'presupuestos',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Presupuesto.fromMap(m)).toList();
  }

  Future<Presupuesto?> getById(int id) async {
    final maps = await _db.query(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Presupuesto.fromMap(maps.first);
  }

  Future<List<PresupuestoItem>> getItems(int presupuestoId) async {
    final maps = await _db.query(
      'presupuesto_items',
      where: 'presupuestoId = ?',
      whereArgs: [presupuestoId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => PresupuestoItem.fromMap(m)).toList();
  }

  Future<List<Presupuesto>> search(String query) async {
    final maps = await _db.query(
      'presupuestos',
      where: 'numero LIKE ? OR nota LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Presupuesto.fromMap(m)).toList();
  }

  // ==================== GENERAR NÚMERO ====================

  Future<String> generarNumero() async {
    final anio = DateTime.now().year;
    final db = await _db.database;

    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM presupuestos WHERE numero LIKE 'PRES-$anio-%'",
    );

    final total = (result.first['total'] as int?) ?? 0;
    final siguiente = (total + 1).toString().padLeft(4, '0');

    return 'PRES-$anio-$siguiente';
  }

  // ==================== GUARDAR (con transacción) ====================

  /// Guarda el presupuesto (cabecera + items) en una transacción
  Future<int> save(Presupuesto presupuesto, List<PresupuestoItem> items) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      int presupuestoId;

      if (presupuesto.id == null) {
        // Insertar cabecera nueva
        final data = presupuesto.toMap();
        data.remove('id');
        presupuestoId = await txn.insert('presupuestos', data);
      } else {
        // Actualizar cabecera existente
        presupuestoId = presupuesto.id!;
        final data = presupuesto.toMap();
        data['id'] = presupuestoId;
        await txn.update(
          'presupuestos',
          data,
          where: 'id = ?',
          whereArgs: [presupuestoId],
        );

        // Borrar los items viejos
        await txn.delete(
          'presupuesto_items',
          where: 'presupuestoId = ?',
          whereArgs: [presupuestoId],
        );
      }

      // Insertar todos los items
      for (final item in items) {
        final itemData = item.toMap();
        itemData['presupuestoId'] = presupuestoId;
        itemData.remove('id');
        await txn.insert('presupuesto_items', itemData);
      }

      return presupuestoId;
    });
  }

  // ==================== ACTUALIZAR ESTADO ====================

  Future<int> actualizarEstado(int id, String nuevoEstado) async {
    final db = await _db.database;
    return await db.update(
      'presupuestos',
      {
        'estado': nuevoEstado,
        'fechaModificacion': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== ELIMINAR ====================

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'presupuesto_items',
        where: 'presupuestoId = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        'presupuestos',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ==================== ESTADÍSTICAS ====================

  Future<int> countByEstado(String estado) async {
    final presupuestos = await getByEstado(estado);
    return presupuestos.length;
  }
}