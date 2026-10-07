import 'package:shared_preferences/shared_preferences.dart';
import '../config/demo_config.dart';

class DemoStatus {
  final bool expirado;
  final int diasRestantes;
  final int horasRestantes;
  final int minutosRestantes;
  final DateTime? fechaInicio;
  final bool modoRapido;

  DemoStatus({
    required this.expirado,
    required this.diasRestantes,
    required this.horasRestantes,
    required this.minutosRestantes,
    this.fechaInicio,
    this.modoRapido = false,
  });

  /// Texto formateado para mostrar en la UI
  String get textoRestante {
    if (expirado) return 'Expirado';
    if (modoRapido) {
      if (minutosRestantes > 0) return '$minutosRestantes min';
      return '${horasRestantes}h ${minutosRestantes}min';
    }
    if (diasRestantes > 0) return '$diasRestantes días';
    if (horasRestantes > 0) return '${horasRestantes}h';
    return '$minutosRestantes min';
  }

  /// Nivel de urgencia (para colores)
  String get urgencia {
    if (expirado) return 'expirado';

    if (modoRapido) {
      // Modo rápido: urgencia según porcentaje del tiempo total
      // Últimos 20% del tiempo → urgente
      // Últimos 50% del tiempo → advertencia
      // Resto → normal
      final totalSegundos = DemoConfig.segundosDemoRapida;
      final restantes = minutosRestantes * 60 + horasRestantes * 3600;
      final porcentaje = restantes / totalSegundos;

      if (porcentaje <= 0.20) return 'urgente';
      if (porcentaje <= 0.50) return 'advertencia';
      return 'normal';
    }

    // Modo real: urgencia según días
    if (diasRestantes <= 1) return 'urgente';
    if (diasRestantes <= 3) return 'advertencia';
    return 'normal';
  }
}

class DemoService {
  /// Inicializa la fecha de inicio (solo la primera vez)
  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(DemoConfig.prefsKeyStartDate)) {
      await prefs.setString(
        DemoConfig.prefsKeyStartDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// Obtiene el estado actual de la demo
  static Future<DemoStatus> obtenerEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(DemoConfig.prefsKeyStartDate);

    if (startStr == null) {
      // No inicializado → sin restricciones
      return DemoStatus(
        expirado: false,
        diasRestantes: DemoConfig.diasDemo,
        horasRestantes: 0,
        minutosRestantes: 0,
      );
    }

    final start = DateTime.parse(startStr);
    final now = DateTime.now();
    final diferencia = now.difference(start);

    if (DemoConfig.modoPruebaRapida) {
      // Modo prueba: usar segundos
      final segundosTotales = DemoConfig.segundosDemoRapida;
      final segundosPasados = diferencia.inSeconds;
      final segundosRestantes = segundosTotales - segundosPasados;
      final expirado = segundosRestantes <= 0;

      final minutos = (segundosRestantes / 60).floor();
      final horas = (minutos / 60).floor();
      final minutosFinales = minutos % 60;

      return DemoStatus(
        expirado: expirado,
        diasRestantes: 0,
        horasRestantes: horas,
        minutosRestantes: minutosFinales,
        fechaInicio: start,
        modoRapido: true,
      );
    } else {
      // Modo real: usar días
      final diasPasados = diferencia.inDays;
      final diasRestantes = DemoConfig.diasDemo - diasPasados;
      final expirado = diasRestantes <= 0;

      final horasRestantes = expirado ? 0 : 24 - diferencia.inHours % 24;
      final minutosRestantes = expirado ? 0 : 60 - diferencia.inMinutes % 60;

      return DemoStatus(
        expirado: expirado,
        diasRestantes: expirado ? 0 : diasRestantes,
        horasRestantes: horasRestantes,
        minutosRestantes: minutosRestantes,
        fechaInicio: start,
        modoRapido: false,
      );
    }
  }

  /// Resetea la demo (borra la fecha de inicio)
  /// ⚠️ Solo para desarrollo
  static Future<void> resetear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DemoConfig.prefsKeyStartDate);
  }
}