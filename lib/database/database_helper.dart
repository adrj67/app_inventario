import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'inventario.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE proveedores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        cuit TEXT,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        contacto TEXT,
        nota TEXT,
        activo INTEGER DEFAULT 1,
        fechaCreacion TEXT NOT NULL,
        fechaModificacion TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    
    await db.insert('proveedores', {
      'nombre': 'Gonzalez Hnos SRL',
      'cuit': '30-12345678-9',
      'telefono': '+54 11 1234-5678',
      'email': 'ventas@gonzalezhnos.com.ar',
      'direccion': 'Av. Corrientes 1234, CABA',
      'contacto': 'Juan Gonzalez',
      'nota': 'Proveedor principal de electrónicos',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });

    await db.insert('proveedores', {
      'nombre': 'PH Mayorista SA',
      'cuit': '30-87654321-9',
      'telefono': '+54 11 9876-5432',
      'email': 'info@phmayorista.com',
      'direccion': 'Calle Falsa 123, CABA',
      'contacto': 'Maria Perez',
      'nota': 'Proveedor de electrodomésticos',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });
  }

  // 🔥 IMPORTANTE: 'table' es POSICIONAL (no named)
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required int id,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}