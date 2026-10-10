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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // ==================== PROVEEDORES ====================
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

    // ==================== PRODUCTOS ====================
    await db.execute('''
        CREATE TABLE productos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sku TEXT NOT NULL,
          codigoBarras TEXT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          categoriaId INTEGER,
          marcaId INTEGER,
          proveedorId INTEGER,
          ubicacionId INTEGER,
          modelo TEXT,
          stockActual INTEGER DEFAULT 0,
          stockMinimo INTEGER DEFAULT 0,
          stockMaximo INTEGER DEFAULT 0,
          unidadMedida TEXT DEFAULT 'Unidad',
          precioCompra REAL DEFAULT 0,
          precioVenta REAL DEFAULT 0,
          precioSugerido REAL,
          margenGanancia REAL,
          fechaCompra TEXT,
          numeroFactura TEXT,
          peso REAL,
          dimensiones TEXT,
          mesesGarantia INTEGER,
          fechaFinGarantia TEXT,
          estaActivo INTEGER DEFAULT 1,
          estaDisponible INTEGER DEFAULT 1,
          estado TEXT DEFAULT 'en_stock',
          fechaCreacion TEXT NOT NULL,
          fechaUltimaModificacion TEXT NOT NULL,
          nota TEXT
        )
      ''');

    // ==================== CATEGORIAS ====================
    await db.execute('''
        CREATE TABLE categorias(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          categoriaPadreId INTEGER,
          activa INTEGER DEFAULT 1,
          fechaCreacion TEXT NOT NULL,
          fechaModificacion TEXT NOT NULL
        )
      ''');

    // ==================== MARCAS ====================
    await db.execute('''
        CREATE TABLE marcas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          activa INTEGER DEFAULT 1,
          fechaCreacion TEXT NOT NULL,
          fechaModificacion TEXT NOT NULL
        )
      ''');

    // ==================== UBICACIONES ====================
    await db.execute('''
          CREATE TABLE ubicaciones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deposito TEXT NOT NULL,
            pasillo TEXT,
            estante TEXT,
            nivel TEXT,
            codigoQR TEXT,
            descripcion TEXT,
            activo INTEGER DEFAULT 1,
            fechaCreacion TEXT NOT NULL,
            fechaModificacion TEXT NOT NULL
          )
        ''');

    // ==================== CLIENTES ====================
    await db.execute('''
          CREATE TABLE clientes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            cuit TEXT,
            telefono TEXT,
            email TEXT,
            direccion TEXT,
            localidad TEXT,
            nota TEXT,
            activo INTEGER DEFAULT 1,
            fechaCreacion TEXT NOT NULL,
            fechaModificacion TEXT NOT NULL
          )
        ''');

    // ==================== MOVIMIENTOS ====================
    await db.execute('''
          CREATE TABLE movimientos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productoId INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            precioUnitario REAL DEFAULT 0,
            motivo TEXT,
            nota TEXT,
            numeroFactura TEXT,
            fecha TEXT NOT NULL,
            usuario TEXT,
            fechaCreacion TEXT NOT NULL
          )
        ''');

    // ==================== CONFIGURACIÓN ====================
    await db.execute('''
          CREATE TABLE configuracion(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombreEmpresa TEXT NOT NULL,
            cuit TEXT,
            direccion TEXT,
            telefono TEXT,
            email TEXT,
            sitioWeb TEXT,
            condicionIva TEXT,
            logoPath TEXT,
            observaciones TEXT,
            fechaModificacion TEXT NOT NULL
          )
        ''');

    // ==================== PRESUPUESTOS ====================
    await db.execute('''
          CREATE TABLE presupuestos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            numero TEXT NOT NULL,
            clienteId INTEGER,
            fecha TEXT NOT NULL,
            fechaVencimiento TEXT NOT NULL,
            subtotal REAL DEFAULT 0,
            iva REAL DEFAULT 0,
            total REAL DEFAULT 0,
            porcentajeIva REAL DEFAULT 21,
            estado TEXT DEFAULT 'pendiente',
            nota TEXT,
            fechaCreacion TEXT NOT NULL,
            fechaModificacion TEXT NOT NULL
          )
        ''');

    await db.execute('''
          CREATE TABLE presupuesto_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            presupuestoId INTEGER NOT NULL,
            productoId INTEGER NOT NULL,
            nombreProducto TEXT NOT NULL,
            sku TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            precioUnitario REAL NOT NULL,
            subtotal REAL NOT NULL,
            nota TEXT
          )
        ''');

    // ==================== HISTORIAL DE PRECIOS ====================
    await db.execute('''
          CREATE TABLE historial_precios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productoId INTEGER NOT NULL,
            precioCompra REAL NOT NULL,
            precioVenta REAL NOT NULL,
            margenGanancia REAL,
            porcentajeGanancia REAL,
            fecha TEXT NOT NULL,
            nota TEXT
          )
        ''');

    // ==================== DATOS DE EJEMPLO ====================
    final now = DateTime.now().toIso8601String(); // SOLO UNA VEZ

    // ----- CONFIGURACIÓN (1) -----
    await db.insert('configuracion', {
      'nombreEmpresa': 'Mi Empresa SRL',
      'cuit': '30-12345678-9',
      'direccion': 'Av. Corrientes 1234, CABA',
      'telefono': '+54 11 1234-5678',
      'email': 'contacto@miempresa.com.ar',
      'sitioWeb': 'www.miempresa.com.ar',
      'condicionIva': 'Responsable Inscripto',
      'logoPath': null,
      'observaciones': 'Configurá los datos de tu empresa desde esta pantalla.',
      'fechaModificacion': now,
    });

    // ----- PROVEEDORES (1) -----
    await db.insert('proveedores', {
      'nombre': 'Proveedor de Ejemplo SRL',
      'cuit': '30-11111111-1',
      'telefono': '+54 11 4444-5555',
      'email': 'ventas@proveedor-ejemplo.com',
      'direccion': 'Av. Belgrano 500, CABA',
      'contacto': 'Juan Pérez',
      'nota': 'Registro de ejemplo. Podés editarlo o eliminarlo.',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });

    // ----- CATEGORÍAS (4 - con jerarquía) -----
    // Raíces
    await db.insert('categorias', {
      'nombre': 'Electrónica',
      'descripcion': 'Productos electrónicos en general',
      'categoriaPadreId': null,
      'activa': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });
    await db.insert('categorias', {
      'nombre': 'Electrodomésticos',
      'descripcion': 'Línea blanca y pequeños electrodomésticos',
      'categoriaPadreId': null,
      'activa': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });
    // Subcategorías (dependen de las raíces)
    await db.insert('categorias', {
      'nombre': 'Celulares',
      'descripcion': 'Smartphones y accesorios',
      'categoriaPadreId': 1, // Electrónica
      'activa': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });
    await db.insert('categorias', {
      'nombre': 'Lavarropas',
      'descripcion': 'Lavadoras automáticas',
      'categoriaPadreId': 2, // Electrodomésticos
      'activa': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });

    // ----- MARCAS (3) -----
    final marcas = [
      {'nombre': 'Samsung', 'descripcion': 'Electrónica coreana'},
      {'nombre': 'LG', 'descripcion': 'Electrónica coreana'},
      {'nombre': 'Drean', 'descripcion': 'Electrodomésticos argentinos'},
    ];
    for (final marca in marcas) {
      await db.insert('marcas', {
        ...marca,
        'activa': 1,
        'fechaCreacion': now,
        'fechaModificacion': now,
      });
    }

    // ----- UBICACIONES (2 - mismo depósito) -----
    await db.insert('ubicaciones', {
      'deposito': 'Depósito Central',
      'pasillo': 'A',
      'estante': '1',
      'nivel': '1',
      'codigoQR': null,
      'descripcion': 'Productos electrónicos',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });
    await db.insert('ubicaciones', {
      'deposito': 'Depósito Central',
      'pasillo': 'B',
      'estante': '1',
      'nivel': '1',
      'codigoQR': null,
      'descripcion': 'Electrodomésticos',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });

    // ----- CLIENTES (1) -----
    await db.insert('clientes', {
      'nombre': 'Cliente de Ejemplo',
      'cuit': '20-12345678-9',
      'telefono': '+54 11 5555-1234',
      'email': 'cliente@ejemplo.com',
      'direccion': 'Av. Rivadavia 1234',
      'localidad': 'CABA',
      'nota': 'Registro de ejemplo. Podés editarlo o eliminarlo.',
      'activo': 1,
      'fechaCreacion': now,
      'fechaModificacion': now,
    });

    // ----- PRODUCTOS (2) -----
    await db.insert('productos', {
      'sku': 'CEL-SAM-A17-001',
      'codigoBarras': '7891234567890',
      'nombre': 'Samsung Galaxy A17',
      'descripcion': 'Smartphone 128GB, 6GB RAM',
      'categoriaId': 3, // Celulares
      'marcaId': 1, // Samsung
      'proveedorId': 1,
      'ubicacionId': 1, // Depósito Central A1-1
      'modelo': 'A17',
      'stockActual': 10,
      'stockMinimo': 3,
      'stockMaximo': 50,
      'unidadMedida': 'Unidad',
      'precioCompra': 180000.0,
      'precioVenta': 250000.0,
      'precioSugerido': 252000.0,
      'fechaCompra': now,
      'numeroFactura': null,
      'peso': null,
      'dimensiones': null,
      'mesesGarantia': 12,
      'fechaFinGarantia': null,
      'estaActivo': 1,
      'estaDisponible': 1,
      'estado': 'en_stock',
      'fechaCreacion': now,
      'fechaUltimaModificacion': now,
      'nota': 'Registro de ejemplo',
    });

    await db.insert('productos', {
      'sku': 'LAV-DRE-NEXT-001',
      'codigoBarras': '7891234567891',
      'nombre': 'Lavarropas Drean Next 8kg',
      'descripcion': 'Lavarropas automático 8kg, 1200 RPM',
      'categoriaId': 4, // Lavarropas
      'marcaId': 3, // Drean
      'proveedorId': 1,
      'ubicacionId': 2, // Depósito Central B1-1
      'modelo': 'Next 8kg',
      'stockActual': 3,
      'stockMinimo': 5, // ⚠️ Stock bajo para que se vea la alerta
      'stockMaximo': 20,
      'unidadMedida': 'Unidad',
      'precioCompra': 450000.0,
      'precioVenta': 620000.0,
      'precioSugerido': 630000.0,
      'fechaCompra': now,
      'numeroFactura': null,
      'peso': null,
      'dimensiones': null,
      'mesesGarantia': 24,
      'fechaFinGarantia': null,
      'estaActivo': 1,
      'estaDisponible': 1,
      'estado': 'stock_bajo',
      'fechaCreacion': now,
      'fechaUltimaModificacion': now,
      'nota': 'Registro de ejemplo con stock bajo',
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
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
