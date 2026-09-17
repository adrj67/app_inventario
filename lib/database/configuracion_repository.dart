import '../models/configuracion.dart';
import 'database_helper.dart';

class ConfiguracionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Obtiene la configuración (siempre es 1 solo registro)
  Future<Configuracion> get() async {
    final maps = await _db.query('configuracion', orderBy: 'id ASC');

    if (maps.isEmpty) {
      // Si no existe, crear la configuración por defecto
      final config = Configuracion.vacia();
      await save(config);
      return config;
    }

    return Configuracion.fromMap(maps.first);
  }

  /// Guarda la configuración (inserta o actualiza)
  Future<int> save(Configuracion config) async {
    final data = config.toMap();

    if (config.id == null) {
      data.remove('id');
      return await _db.insert('configuracion', data);
    } else {
      data['id'] = config.id;
      return await _db.update('configuracion', data, id: config.id!);
    }
  }
}