import 'package:flutter/material.dart';
import '../services/export_helper.dart';

class ExportButton extends StatelessWidget {
  final String titulo;
  final List<String> headers;
  final List<List<String>> rows;
  final MaterialColor? color;

  const ExportButton({
    super.key,
    required this.titulo,
    required this.headers,
    required this.rows,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.blue;

    return Tooltip(
      message: 'Exportar a CSV o PDF',
      child: OutlinedButton.icon(
        onPressed: () => ExportHelper.mostrarDialogoExportacion(
          context: context,
          titulo: titulo,
          headers: headers,
          rows: rows,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: baseColor.shade700,
          side: BorderSide(color: baseColor.shade700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.file_download, size: 18),
        label: const Text(
          'Exportar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}