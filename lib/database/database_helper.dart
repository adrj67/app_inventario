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

      // ==================== DATOS DE EJEMPLO ====================
      final now = DateTime.now().toIso8601String();  // 🔥 SOLO UNA VEZ
      
      // Proveedores de ejemplo
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

      // 🔥 Productos de ejemplo (SIN volver a declarar 'now')
      final productosEjemplo = [
        {
          'sku': 'CEL-SAM-A17-001',
          'codigoBarras': '7891234567890',
          'nombre': 'Samsung Galaxy A17',
          'descripcion': 'Smartphone 128GB, 6GB RAM',
          'categoriaId': 1,
          'marcaId': 1,
          'proveedorId': 1,
          'modelo': 'A17',
          'stockActual': 15,
          'stockMinimo': 5,
          'stockMaximo': 50,
          'precioCompra': 180000.0,
          'precioVenta': 250000.0,
          'fechaCompra': now,
          'estaActivo': 1,
          'estaDisponible': 1,
          'estado': 'en_stock',
          'fechaCreacion': now,
          'fechaUltimaModificacion': now,
        },
        {
          'sku': 'LAV-DRE-SW120-001',
          'codigoBarras': '7891234567891',
          'nombre': 'Lavarropas Drean Next 8kg',
          'descripcion': 'Lavarropas automático 8kg',
          'categoriaId': 2,
          'marcaId': 2,
          'proveedorId': 2,
          'modelo': 'SW120PN',
          'stockActual': 3,
          'stockMinimo': 5,
          'stockMaximo': 20,
          'precioCompra': 450000.0,
          'precioVenta': 620000.0,
          'fechaCompra': now,
          'estaActivo': 1,
          'estaDisponible': 1,
          'estado': 'en_stock',
          'fechaCreacion': now,
          'fechaUltimaModificacion': now,
        },
        {
          'sku': 'COL-SUA-2P-001',
          'codigoBarras': '7891234567892',
          'nombre': 'Colchón Suavestar 2 Plazas',
          'descripcion': 'Colchón resortes 2 plazas',
          'categoriaId': 3,
          'marcaId': 3,
          'proveedorId': 1,
          'modelo': 'Confort',
          'stockActual': 0,
          'stockMinimo': 3,
          'stockMaximo': 15,
          'precioCompra': 220000.0,
          'precioVenta': 320000.0,
          'fechaCompra': now,
          'estaActivo': 1,
          'estaDisponible': 1,
          'estado': 'agotado',
          'fechaCreacion': now,
          'fechaUltimaModificacion': now,
        },
        {
          'sku': 'AUR-JBL-TUNE-001',
          'codigoBarras': '7891234567893',
          'nombre': 'Auriculares JBL Tune 510BT',
          'descripcion': 'Auriculares inalámbricos',
          'categoriaId': 1,
          'marcaId': 4,
          'proveedorId': 1,
          'modelo': 'Tune 510BT',
          'stockActual': 25,
          'stockMinimo': 10,
          'stockMaximo': 100,
          'precioCompra': 45000.0,
          'precioVenta': 72000.0,
          'fechaCompra': now,
          'estaActivo': 1,
          'estaDisponible': 1,
          'estado': 'en_stock',
          'fechaCreacion': now,
          'fechaUltimaModificacion': now,
        },
        {
          'sku': 'TAB-LEN-M10-001',
          'codigoBarras': '7891234567894',
          'nombre': 'Tablet Lenovo M10',
          'descripcion': 'Tablet 10" 64GB',
          'categoriaId': 1,
          'marcaId': 5,
          'proveedorId': 2,
          'modelo': 'M10',
          'stockActual': 8,
          'stockMinimo': 5,
          'stockMaximo': 30,
          'precioCompra': 150000.0,
          'precioVenta': 210000.0,
          'fechaCompra': now,
          'estaActivo': 1,
          'estaDisponible': 1,
          'estado': 'en_stock',
          'fechaCreacion': now,
          'fechaUltimaModificacion': now,
        },
      ];

      for (final producto in productosEjemplo) {
        await db.insert('productos', producto);
      }

      // Categorías de ejemplo
      final categoriasEjemplo = [
        {'nombre': 'Electrónica', 'descripcion': 'Productos electrónicos', 'categoriaPadreId': null},
        {'nombre': 'Celulares', 'descripcion': 'Smartphones y accesorios', 'categoriaPadreId': 1},
        {'nombre': 'Smartphones', 'descripcion': 'Teléfonos inteligentes', 'categoriaPadreId': 2},
        {'nombre': 'Accesorios', 'descripcion': 'Fundas, cargadores', 'categoriaPadreId': 2},
        {'nombre': 'Electrodomésticos', 'descripcion': 'Línea blanca', 'categoriaPadreId': null},
        {'nombre': 'Lavarropas', 'descripcion': 'Lavadoras', 'categoriaPadreId': 5},
        {'nombre': 'Heladeras', 'descripcion': 'Refrigeradores', 'categoriaPadreId': 5},
        {'nombre': 'Muebles', 'descripcion': 'Mobiliario', 'categoriaPadreId': null},
        {'nombre': 'Colchones', 'descripcion': 'Colchones y sommiers', 'categoriaPadreId': 8},
      ];

      for (final cat in categoriasEjemplo) {
        await db.insert('categorias', {
          ...cat,
          'activa': 1,
          'fechaCreacion': now,
          'fechaModificacion': now,
        });
      }

      // Marcas de ejemplo
      final marcasEjemplo = [
        {'nombre': 'Samsung', 'descripcion': 'Electrónica coreana'},
        {'nombre': 'Drean', 'descripcion': 'Electrodomésticos argentinos'},
        {'nombre': 'Suavestar', 'descripcion': 'Colchones'},
        {'nombre': 'JBL', 'descripcion': 'Audio profesional'},
        {'nombre': 'Lenovo', 'descripcion': 'Tecnología china'},
        {'nombre': 'Sony', 'descripcion': 'Electrónica japonesa'},
        {'nombre': 'LG', 'descripcion': 'Electrónica coreana'},
        {'nombre': 'Philips', 'descripcion': 'Electrónica holandesa'},
      ];

      for (final marca in marcasEjemplo) {
        await db.insert('marcas', {
          ...marca,
          'activa': 1,
          'fechaCreacion': now,
          'fechaModificacion': now,
        });
      }

      // Ubicaciones de ejemplo
      final ubicacionesEjemplo = [
        {'deposito': 'Depósito Central', 'pasillo': 'A', 'estante': '1', 'nivel': '1', 'descripcion': 'Productos electrónicos'},
        {'deposito': 'Depósito Central', 'pasillo': 'A', 'estante': '2', 'nivel': '1', 'descripcion': 'Celulares'},
        {'deposito': 'Depósito Central', 'pasillo': 'B', 'estante': '1', 'nivel': '1', 'descripcion': 'Electrodomésticos'},
        {'deposito': 'Depósito Norte', 'pasillo': 'A', 'estante': '1', 'nivel': '1', 'descripcion': 'Muebles grandes'},
        {'deposito': 'Depósito Norte', 'pasillo': 'A', 'estante': '1', 'nivel': '2', 'descripcion': 'Colchones'},
      ];

      for (final ubic in ubicacionesEjemplo) {
        await db.insert('ubicaciones', {
          ...ubic,
          'activo': 1,
          'fechaCreacion': now,
          'fechaModificacion': now,
        });
      }

      // Clientes de ejemplo
      final clientesEjemplo = [
        {
          'nombre': 'Consumidor Final',
          'cuit': '20-12345678-9',
          'telefono': '+54 11 5555-1234',
          'email': 'consumidor.final@email.com',
          'direccion': 'Av. Rivadavia 1234',
          'localidad': 'CABA',
          'nota': 'Cliente frecuente',
        },
        {
          'nombre': 'María González',
          'cuit': '27-87654321-4',
          'telefono': '+54 11 5555-5678',
          'email': 'maria.gonzalez@email.com',
          'direccion': 'Calle Mitre 567',
          'localidad': 'Vicente López',
          'nota': null,
        },
        {
          'nombre': 'Empresa XYZ SRL',
          'cuit': '30-71234567-8',
          'telefono': '+54 11 4444-9876',
          'email': 'compras@empresaXYZ.com',
          'direccion': 'Av. Corrientes 1234, Piso 5',
          'localidad': 'CABA',
          'nota': 'Cliente corporativo - paga a 30 días',
        },
        {
          'nombre': 'Carlos Rodríguez',
          'cuit': '20-45678912-3',
          'telefono': '+54 11 6666-7890',
          'email': 'carlos.r@email.com',
          'direccion': 'Calle Belgrano 890',
          'localidad': 'San Isidro',
          'nota': null,
        },
        {
          'nombre': 'Lucía Fernández',
          'cuit': '27-98765432-1',
          'telefono': '+54 11 7777-2345',
          'email': 'lucia.f@email.com',
          'direccion': 'Av. Santa Fe 3456',
          'localidad': 'CABA',
          'nota': 'Prefiere contacto por WhatsApp',
        },
      ];

      for (final cliente in clientesEjemplo) {
        await db.insert('clientes', {
          ...cliente,
          'activo': 1,
          'fechaCreacion': now,
          'fechaModificacion': now,
        });
      }

      // Configuración por defecto
      await db.insert('configuracion', {
        'nombreEmpresa': 'Mi Empresa SRL',
        'cuit': '30-12345678-9',
        'direccion': 'Av. Corrientes 1234, CABA',
        'telefono': '+54 11 1234-5678',
        'email': 'contacto@miempresa.com.ar',
        'sitioWeb': 'www.miempresa.com.ar',
        'condicionIva': 'Responsable Inscripto',
        'logoPath': null,
        'observaciones': null,
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