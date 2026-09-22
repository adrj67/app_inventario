import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
//import 'package:path_provider/path_provider.dart';
import '../models/configuracion.dart';
import '../models/cliente.dart';
import '../models/presupuesto.dart';
import '../models/presupuesto_item.dart';
import 'export_service.dart';

class PresupuestoPdfService {
  static Future<void> generarPdfPresupuesto({
    required Presupuesto presupuesto,
    required List<PresupuestoItem> items,
    required Cliente? cliente,
    required Configuracion config,
  }) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Cargar logo si existe
    pw.ImageProvider? logoImage;
    if (config.logoPath != null) {
      try {
        final logoFile = File(config.logoPath!);
        if (await logoFile.exists()) {
          logoImage = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(config, logoImage, presupuesto, dateFormat),
        footer: (context) => _buildFooter(context, config),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildDatosClienteYPresupuesto(cliente, presupuesto, dateFormat),
          pw.SizedBox(height: 16),
          _buildTablaProductos(items, currencyFormat),
          pw.SizedBox(height: 16),
          _buildTotales(presupuesto, currencyFormat),
          pw.SizedBox(height: 16),
          _buildLeyendas(presupuesto, dateFormat),
          if (presupuesto.nota != null && presupuesto.nota!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotas(presupuesto.nota!),
          ],
        ],
      ),
    );

    // Guardar en Descargas y abrir
    final bytes = await pdf.save();
    final nombreArchivo =
        'presupuesto_${presupuesto.numero.replaceAll('-', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

    await ExportService.sharePdfBytes(
      bytes: bytes,
      nombreArchivo: nombreArchivo,
    );
  }

  // ==================== HEADER ====================

  static pw.Widget _buildHeader(
    Configuracion config,
    pw.ImageProvider? logo,
    Presupuesto presupuesto,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo o iniciales
            if (logo != null)
              pw.Container(
                width: 60,
                height: 60,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 60,
                height: 60,
                margin: const pw.EdgeInsets.only(right: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    config.nombreEmpresa.substring(0, 1).toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Datos de la empresa
            pw.Expanded(
              child: pw.Column(
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
                    pw.Text(
                      'CUIT: ${config.cuit}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (config.condicionIva != null)
                    pw.Text(
                      config.condicionIva!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (config.direccion != null)
                    pw.Text(
                      config.direccion!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (config.telefono != null)
                    pw.Text(
                      'Tel: ${config.telefono}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (config.email != null)
                    pw.Text(
                      config.email!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),

            // Título del documento
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.deepOrange,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'PRESUPUESTO',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  presupuesto.numero,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Fecha: ${dateFormat.format(presupuesto.fecha)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey400, thickness: 1),
      ],
    );
  }

  // ==================== DATOS CLIENTE ====================

  static pw.Widget _buildDatosClienteYPresupuesto(
    Cliente? cliente,
    Presupuesto presupuesto,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS DEL CLIENTE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  cliente?.nombre ?? 'Consumidor Final',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (cliente?.cuit != null)
                  pw.Text('CUIT: ${cliente!.cuit}',
                      style: const pw.TextStyle(fontSize: 10)),
                if (cliente?.direccion != null)
                  pw.Text(cliente!.direccion!,
                      style: const pw.TextStyle(fontSize: 10)),
                if (cliente?.localidad != null)
                  pw.Text(cliente!.localidad!,
                      style: const pw.TextStyle(fontSize: 10)),
                if (cliente?.telefono != null)
                  pw.Text('Tel: ${cliente!.telefono}',
                      style: const pw.TextStyle(fontSize: 10)),
                if (cliente?.email != null)
                  pw.Text(cliente!.email!,
                      style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'VENCIMIENTO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  dateFormat.format(presupuesto.fechaVencimiento),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ESTADO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _colorEstado(presupuesto.estado),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    presupuesto.estado.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _colorEstado(String estado) {
    switch (estado) {
      case 'aprobado':
        return PdfColors.green700;
      case 'rechazado':
        return PdfColors.red700;
      case 'vencido':
        return PdfColors.grey600;
      default:
        return PdfColors.orange700;
    }
  }

  // ==================== TABLA PRODUCTOS ====================

  static pw.Widget _buildTablaProductos(
    List<PresupuestoItem> items,
    NumberFormat currencyFormat,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: const ['#', 'Descripción', 'SKU', 'Cant.', 'Precio Unit.', 'Subtotal'],
      data: items.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final item = entry.value;
        return [
          i.toString(),
          item.nombreProducto,
          item.sku,
          item.cantidad.toString(),
          currencyFormat.format(item.precioUnitario),
          currencyFormat.format(item.subtotal),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      cellPadding: const pw.EdgeInsets.all(6),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  // ==================== TOTALES ====================

  static pw.Widget _buildTotales(
    Presupuesto presupuesto,
    NumberFormat currencyFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              _buildFilaTotal(
                'Subtotal:',
                currencyFormat.format(presupuesto.subtotal),
                false,
              ),
              pw.SizedBox(height: 4),
              _buildFilaTotal(
                'IVA (${presupuesto.porcentajeIva.toStringAsFixed(1)}%):',
                currencyFormat.format(presupuesto.iva),
                false,
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              _buildFilaTotal(
                'TOTAL:',
                currencyFormat.format(presupuesto.total),
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFilaTotal(String label, String valor, bool destacado) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: destacado ? 12 : 10,
            fontWeight: destacado ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: destacado ? 14 : 10,
            fontWeight: pw.FontWeight.bold,
            color: destacado ? PdfColors.green800 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  // ==================== LEYENDAS ====================

  static pw.Widget _buildLeyendas(
    Presupuesto presupuesto,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Vencimiento destacado
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red300, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'Vencimiento del presupuesto: ${dateFormat.format(presupuesto.fechaVencimiento)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red900,
            ),
          ),
        ),
        pw.SizedBox(height: 8),

        // No válido como factura
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'NO VÁLIDO COMO FACTURA',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== NOTAS ====================

  static pw.Widget _buildNotas(String nota) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACIONES',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            nota,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== FOOTER ====================

  static pw.Widget _buildFooter(pw.Context context, Configuracion config) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            config.sitioWeb ?? config.email ?? '',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}