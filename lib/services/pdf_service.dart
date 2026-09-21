import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
//import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/configuracion.dart';
import 'export_service.dart';

class PdfService {
  /// Genera un PDF genérico de tabla (para exportar cualquier listado)
  static Future<void> generarPdfTabla({
    required String titulo,
    required List<String> headers,
    required List<List<String>> rows,
    required Configuracion config,
    List<double>? columnWidths,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final fechaGeneracion = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(titulo, config, fechaGeneracion),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildTabla(headers, rows, columnWidths),
        ],
      ),
    );

    // Guardar el PDF en Descargas y abrirlo
    final bytes = await pdf.save();
    final nombreArchivo =
        '${titulo.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    await ExportService.sharePdfBytes(
      bytes: bytes,
      nombreArchivo: nombreArchivo.replaceAll('.pdf', ''),
    );
  }

  /// Header del PDF con datos de la empresa
  static pw.Widget _buildHeader(
    String titulo,
    Configuracion config,
    String fechaGeneracion,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  config.nombreEmpresa,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (config.cuit != null)
                  pw.Text('CUIT: ${config.cuit}',
                      style: const pw.TextStyle(fontSize: 10)),
                if (config.direccion != null)
                  pw.Text(config.direccion!,
                      style: const pw.TextStyle(fontSize: 10)),
                if (config.telefono != null)
                  pw.Text('Tel: ${config.telefono}',
                      style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: $fechaGeneracion',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.blue800, thickness: 2),
      ],
    );
  }

  /// Footer con número de página
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  /// Tabla con headers y filas
  static pw.Widget _buildTabla(
    List<String> headers,
    List<List<String>> rows,
    List<double>? columnWidths,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(4),
      columnWidths: columnWidths != null
          ? {
              for (int i = 0; i < columnWidths.length; i++)
                i: pw.FixedColumnWidth(columnWidths[i]),
            }
          : null,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  /// Formatea valores monetarios
  static String formatearMoneda(double valor) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(valor);
  }
}