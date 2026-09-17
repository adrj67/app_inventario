import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  /// Exporta datos a un archivo CSV y lo comparte
  static Future<void> exportToCsv({
    required String nombreArchivo,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    // 1. Crear el CSV
    final List<List<dynamic>> data = [headers, ...rows];
    final String csv = const ListToCsvConverter().convert(data);

    // 2. Guardar en Documentos
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // 3. Compartir / Abrir
    await Share.shareXFiles(
      [XFile(path)],
      subject: nombreArchivo,
    );
  }

  /// Genera un nombre de archivo con fecha actual
  static String generarNombreArchivo(String prefijo) {
    final ahora = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefijo}_$ahora';
  }

  /// Abre un archivo PDF desde bytes
  static Future<void> sharePdfBytes({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path)],
      subject: nombreArchivo,
    );
  }
}