class DemoConfig {
  /// 🔥 CAMBIAR A `true` PARA PROBAR RÁPIDO (usa segundos en lugar de días)
  /// 🔥 DEJAR EN `false` PARA PRODUCCIÓN
  static const bool modoPruebaRapida = true;

  /// Días de la demo real
  static const int diasDemo = 7;

  /// Segundos de la demo rápida (para testear)
  /// 120 segundos = 2 minutos
  static const int segundosDemoRapida = 120;

  /// Datos de contacto al expirar
  static const String emailContacto = 'adrj67@gmail.com';
  static const String telefonoContacto = '+54 223 400-1010';

  /// Clave para SharedPreferences
  static const String prefsKeyStartDate = 'demo_start_date';

  /// Bandera de compilación: si es `false`, no aplica el límite de demo
  /// Se define al compilar con --dart-define=IS_DEMO=true/false
  static const bool isDemo = bool.fromEnvironment('IS_DEMO', defaultValue: true);
}