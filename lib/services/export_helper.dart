import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/configuracion_repository.dart';
import 'export_service.dart';
import 'pdf_service.dart';

class ExportHelper {
    /// Muestra un diálogo para elegir CSV o PDF
  static Future<void> mostrarDialogoExportacion({
    required BuildContext context,
    required String titulo,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formato = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.file_download, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Exportar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿En qué formato querés exportar "$titulo"?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${rows.length} registros',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'csv'),
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade700),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'pdf'),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (formato == null) return;

    // 🔥 GUARD: Si el widget ya no está montado, salir
    if (!context.mounted) return;

    try {
      if (formato == 'csv') {
        await _exportarCsv(titulo: titulo, headers: headers, rows: rows);
      } else {
        await _exportarPdf(titulo: titulo, headers: headers, rows: rows);
      }

      // 🔥 GUARD después del await
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            formato == 'csv'
                ? 'CSV abierto en el programa predeterminado'
                : 'PDF generado correctamente',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    static Future<void> _exportarCsv({
    required String titulo,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final nombreArchivo =
        '${titulo.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

    await ExportService.exportToCsv(
      nombreArchivo: nombreArchivo,
      headers: headers,
      rows: rows,
    );
  }

  static Future<void> _exportarPdf({
    required String titulo,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final config = await ConfiguracionRepository().get();

    await PdfService.generarPdfTabla(
      titulo: titulo,
      headers: headers,
      rows: rows,
      config: config,
    );
  }
}