import 'package:flutter/foundation.dart';

import '../models/configuracion.dart';
import 'database_helper.dart';

class ConfiguracionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Obtiene la configuración (siempre es 1 solo registro)
  Future<Configuracion> get() async {
    final maps = await _db.query('configuracion', orderBy: 'id ASC');

    if (maps.isEmpty) {
      final config = Configuracion.vacia();
      await save(config);
      return config;
    }

    return Configuracion.fromMap(maps.first);
  }

  /// Guarda la configuración (inserta o actualiza)
  Future<int> save(Configuracion config) async {
    final data = config.toMap();

    // 🔥 DEBUG
    debugPrint('=== SAVE CONFIG ===');
    debugPrint('ID: ${config.id}');
    debugPrint('logoPath en objeto: ${config.logoPath}');
    debugPrint('logoPath en map: ${data['logoPath']}');
    debugPrint('===================');

    if (config.id == null) {
      data.remove('id');
      final id = await _db.insert('configuracion', data);
      debugPrint('Insertado con ID: $id');
      return id;
    } else {
      data['id'] = config.id;
      final resultado = await _db.update('configuracion', data, id: config.id!);
      debugPrint('Actualizado, filas afectadas: $resultado');
      return resultado;
    }
  }
}