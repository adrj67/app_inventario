import 'dart:convert';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import 'package:flutter/foundation.dart';

class BackupInfo {
  final File archivo;
  final DateTime fecha;
  final int tamanioBytes;

  BackupInfo({
    required this.archivo,
    required this.fecha,
    required this.tamanioBytes,
  });

  String get nombreArchivo => path.basename(archivo.path);

  String get tamanioFormateado {
    if (tamanioBytes < 1024) return '$tamanioBytes B';
    if (tamanioBytes < 1024 * 1024) {
      return '${(tamanioBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanioBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupService {
  static const String _carpetaBackup = 'InventarioPro';
  static const String _subcarpeta = 'backups';
  static const int _maxBackups = 7;
  //static const String _prefsKeyUltimoBackup = 'ultimo_backup_fecha';

  /// Lista de tablas a exportar (en orden de dependencias)
  static const List<String> _tablas = [
    'configuracion',
    'proveedores',
    'categorias',
    'marcas',
    'ubicaciones',
    'clientes',
    'productos',
    'movimientos',
    'presupuestos',
    'presupuesto_items',
    'historial_precios',
  ];

  // ==================== CARPETA ====================

  /// Obtiene (y crea si no existe) la carpeta de backups
  static Future<Directory> _obtenerCarpetaBackups() async {
    final documents = await getApplicationDocumentsDirectory();
    final carpeta = Directory(
      path.join(documents.path, _carpetaBackup, _subcarpeta),
    );

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    return carpeta;
  }

  // ==================== CREAR BACKUP ====================

  /// Crea un backup completo de la DB
  /// Devuelve el archivo creado
  static Future<File> crearBackup() async {
    final db = await DatabaseHelper().database;
    final carpeta = await _obtenerCarpetaBackups();

    // Exportar todas las tablas
    final Map<String, dynamic> datos = {};
    for (final tabla in _tablas) {
      final rows = await db.query(tabla);
      datos[tabla] = rows;
    }

    // Estructura del backup
    final backup = {
      'version': '1.0',
      'app': 'Inventario Pro',
      'fecha': DateTime.now().toIso8601String(),
      'tablas': _tablas,
      'datos': datos,
    };

    // Nombre del archivo: backup_2026-10-07_14-30-00.json
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final archivo = File(path.join(carpeta.path, 'backup_$timestamp.json'));

    // Escribir JSON formateado
    const encoder = JsonEncoder.withIndent('  ');
    await archivo.writeAsString(encoder.convert(backup));

    // Rotar backups viejos
    await _rotarBackups();

    // Guardar la fecha del último backup
    await _guardarFechaUltimoBackup(DateTime.now());

    return archivo;
  }

  // ==================== LISTAR ====================

  /// Lista todos los backups disponibles, ordenados por fecha DESC
  static Future<List<BackupInfo>> listarBackups() async {
    final carpeta = await _obtenerCarpetaBackups();
    final archivos = carpeta
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final backups = <BackupInfo>[];
    for (final archivo in archivos) {
      try {
        final stat = await archivo.stat();

        // 🔥 Extraer fecha del nombre: backup_2026-10-08_08-51-13.json
        final nombre = path.basenameWithoutExtension(archivo.path);
        final sinPrefijo = nombre.replaceFirst('backup_', '');
        // sinPrefijo = "2026-10-08_08-51-13"

        final partes = sinPrefijo.split('_');
        if (partes.length == 2) {
          // partes[0] = "2026-10-08"
          // partes[1] = "08-51-13"
          final fechaPartes = partes[0].split('-'); // [2026, 10, 08]
          final horaPartes = partes[1].split('-'); // [08, 51, 13]

          if (fechaPartes.length == 3 && horaPartes.length == 3) {
            final fechaCompleta = DateTime(
              int.parse(fechaPartes[0]), // año
              int.parse(fechaPartes[1]), // mes
              int.parse(fechaPartes[2]), // día
              int.parse(horaPartes[0]),  // hora
              int.parse(horaPartes[1]),  // minuto
              int.parse(horaPartes[2]),  // segundo
            );

            backups.add(BackupInfo(
              archivo: archivo,
              fecha: fechaCompleta,
              tamanioBytes: stat.size,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error parseando backup ${archivo.path}: $e');
      }
    }

    // Ordenar por fecha descendente (más nuevos primero)
    backups.sort((a, b) => b.fecha.compareTo(a.fecha));

    return backups;
  }

  // ==================== ROTACIÓN ====================

  /// Elimina los backups más viejos, manteniendo solo los últimos N
  static Future<int> _rotarBackups() async {
    final backups = await listarBackups();

    if (backups.length <= _maxBackups) return 0;

    int eliminados = 0;
    for (int i = _maxBackups; i < backups.length; i++) {
      try {
        await backups[i].archivo.delete();
        eliminados++;
      } catch (e) {
        // Ignorar errores
      }
    }

    return eliminados;
  }

  // ==================== FECHA ÚLTIMO BACKUP ====================

  static Future<void> _guardarFechaUltimoBackup(DateTime fecha) async {
    final documents = await getApplicationDocumentsDirectory();
    final archivo = File(
      path.join(documents.path, _carpetaBackup, 'ultimo_backup.txt'),
    );
    await archivo.writeAsString(fecha.toIso8601String());
  }

  static Future<DateTime?> obtenerFechaUltimoBackup() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final archivo = File(
        path.join(documents.path, _carpetaBackup, 'ultimo_backup.txt'),
      );
      if (!await archivo.exists()) return null;
      final contenido = await archivo.readAsString();
      return DateTime.parse(contenido);
    } catch (e) {
      return null;
    }
  }

  // ==================== AUTO-BACKUP ====================

  /// Verifica si hay que hacer backup (si pasaron más de 24 hs)
  static Future<bool> necesitaBackupAutomatico() async {
    final ultimo = await obtenerFechaUltimoBackup();
    if (ultimo == null) return true;

    final diferencia = DateTime.now().difference(ultimo);
    return diferencia.inHours >= 24;
  }

  /// Ejecuta el backup automático si es necesario
  /// Devuelve `true` si se hizo un backup
  static Future<bool> ejecutarBackupAutomatico() async {
    if (!await necesitaBackupAutomatico()) return false;

    try {
      await crearBackup();
      return true;
    } catch (e) {
      debugPrint('Error en backup automático: $e');
      return false;
    }
  }

  // ==================== RESTAURAR ====================

  /// Restaura un backup sobre la DB actual
  /// ⚠️ Hace un backup del estado actual antes de restaurar (por seguridad)
  static Future<void> restaurarBackup(File archivoBackup) async {
    // 1. Leer el JSON
    final contenido = await archivoBackup.readAsString();
    final Map<String, dynamic> backup = jsonDecode(contenido);

    if (!backup.containsKey('datos')) {
      throw Exception('El archivo no tiene un formato válido');
    }

    // 2. Hacer backup de seguridad del estado actual
    await crearBackup();

    // 3. Obtener la DB
    final db = await DatabaseHelper().database;

    // 4. Restaurar en una transacción
    await db.transaction((txn) async {
      // Limpiar todas las tablas (excepto sqlite_sequence)
      for (final tabla in _tablas) {
        await txn.delete(tabla);
      }

      // Insertar datos del backup
      final datos = backup['datos'] as Map<String, dynamic>;
      for (final tabla in _tablas) {
        if (!datos.containsKey(tabla)) continue;
        final rows = datos[tabla] as List<dynamic>;
        for (final row in rows) {
          await txn.insert(tabla, Map<String, dynamic>.from(row));
        }
      }
    });
  }

  // ==================== INFO ====================

  /// Obtiene la ruta donde se guardan los backups
  static Future<String> obtenerRutaBackups() async {
    final carpeta = await _obtenerCarpetaBackups();
    return carpeta.path;
  }

  /// Cuenta cuántos backups hay
  static Future<int> contarBackups() async {
    final backups = await listarBackups();
    return backups.length;
  }
}