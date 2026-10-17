//import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/configuracion.dart';
import 'export_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PdfService {
  // Genera un PDF genérico de tabla (para exportar cualquier listado)
  static Future<void> generarPdfTabla({
    required String titulo,
    required List<String> headers,
    required List<List<String>> rows,
    required Configuracion config,
    List<double>? columnWidths,
    String? leyendaFiltros,
  }) async {
    final pdf = pw.Document();

    // 🔥 Cargar logo si existe
        // 🔥 Cargar logo si existe
    pw.ImageProvider? logoImage;
    if (config.logoPath != null) {
      try {
        final logoFile = File(config.logoPath!);
        final existe = await logoFile.exists();
        final tamanio = existe ? (await logoFile.stat()).size : 0;
        
        // 🔥 DEBUG
        debugPrint('=== LOGO EN PDF ===');
        debugPrint('Ruta: ${config.logoPath}');
        debugPrint('Existe: $existe');
        debugPrint('tamanio: $tamanio bytes');
        debugPrint('===================');
        
        if (existe && tamanio > 0) {
          logoImage = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint('Error cargando logo: $e');
      }
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final fechaGeneracion = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        // 🔥 Pasar logoImage al header
        header: (context) => _buildHeader(
          titulo,
          config,
          fechaGeneracion,
          logoImage,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          if (leyendaFiltros != null && leyendaFiltros.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    '🔍  ',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      leyendaFiltros,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildTabla(headers, rows, columnWidths),
        ],
      ),
    );

    // Guardar el PDF en Descargas
    final bytes = await pdf.save();
    final nombreArchivo =
        '${titulo.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    await ExportService.sharePdfBytes(
      bytes: bytes,
      nombreArchivo: nombreArchivo.replaceAll('.pdf', ''),
    );
  }

  // Header del PDF con datos de la empresa + logo opcional
  static pw.Widget _buildHeader(
    String titulo,
    Configuracion config,
    String fechaGeneracion,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo + datos de la empresa
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo (si existe)
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  // Datos de la empresa
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          config.nombreEmpresa,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (config.cuit != null)
                          pw.Text('CUIT: ${config.cuit}',
                              style: const pw.TextStyle(fontSize: 9)),
                        if (config.direccion != null)
                          pw.Text(config.direccion!,
                              style: const pw.TextStyle(fontSize: 9)),
                        if (config.telefono != null)
                          pw.Text('Tel: ${config.telefono}',
                              style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Título + fecha
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

  // Footer con número de página
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

  // Tabla con headers y filas
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

  // Formatea valores monetarios
  static String formatearMoneda(double valor) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(valor);
  }
}