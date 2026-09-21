import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExportService {
  /// Exporta datos a un archivo CSV y lo abre con el programa predeterminado
  static Future<void> exportToCsv({
    required String nombreArchivo,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    // 1. Crear el CSV (con BOM UTF-8 para que Excel respete acentos)
    final List<List<dynamic>> data = [headers, ...rows];
    final String csvBody = const ListToCsvConverter().convert(data);
    final String csv = '\uFEFF$csvBody';

    // 2. Guardar en Descargas
    final directory = await _obtenerCarpetaDescargas();
    final path = '${directory.path}/$nombreArchivo.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // 3. Abrir con el programa predeterminado
    await _abrirArchivo(file);
  }

  /// Obtiene la carpeta de Descargas (con fallback a Documentos)
  static Future<Directory> _obtenerCarpetaDescargas() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        // Verificar que exista
        if (!await downloads.exists()) {
          await downloads.create(recursive: true);
        }
        return downloads;
      }
    } catch (e) {
      // Fallback
    }

    // Si falla, usar Documentos
    return await getApplicationDocumentsDirectory();
  }

  /// Abre un archivo con el programa predeterminado del sistema
  static Future<void> _abrirArchivo(File file) async {
    final uri = Uri.file(file.path);

    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', file.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No se pudo abrir el archivo: $e');
      }
    }
  }

  /// Genera un nombre de archivo con fecha actual
  static String generarNombreArchivo(String prefijo) {
    final ahora = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefijo}_$ahora';
  }

  /// Comparte un archivo (para PDF, WhatsApp, etc.)
  static Future<void> sharePdfBytes({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final directory = await _obtenerCarpetaDescargas();
    final path = '${directory.path}/$nombreArchivo.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    await _abrirArchivo(file);
  }
}