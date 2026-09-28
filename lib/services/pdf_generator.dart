import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/vehiculo.dart';

/// Genera y abre el PDF de la **Orden de Mantenimiento** recién creada.
Future<void> generarOrdenPdf({
  required int id,
  required Vehiculo vehiculo,
  required String mecanico,
  required String tipo,
  String? tipoDetalle,
  String? indicaciones,
}) async {
  final doc = pw.Document();
  final ahora = DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  final fecha =
      '${dos(ahora.day)}/${dos(ahora.month)}/${ahora.year} ${dos(ahora.hour)}:${dos(ahora.minute)}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _encabezado('ORDEN DE MANTENIMIENTO'),
          pw.SizedBox(height: 12),
          _campo('N° de orden', '#$id'),
          _campo('Fecha de emisión', fecha),
          _campo('Estado', 'Pendiente de inspección'),
          pw.SizedBox(height: 16),
          pw.Text('Vehículo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _campo('Descripción', vehiculo.descripcion),
          if (vehiculo.categoria != null) _campo('Categoría', vehiculo.categoria!),
          if (vehiculo.anio != null) _campo('Año', '${vehiculo.anio}'),
          if (vehiculo.color != null) _campo('Color', vehiculo.color!),
          if (vehiculo.kilometraje != null)
            _campo('Kilometraje', '${vehiculo.kilometraje} km'),
          pw.SizedBox(height: 16),
          pw.Text('Asignación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _campo('Mecánico', mecanico),
          _campo('Tipo de mantenimiento', tipoDetalle == null ? tipo : '$tipo ($tipoDetalle)'),
          pw.SizedBox(height: 16),
          pw.Text('Indicaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text((indicaciones == null || indicaciones.isEmpty) ? 'Sin indicaciones.' : indicaciones),
          pw.Spacer(),
          _pie(),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

/// Genera y abre el PDF del **Comprobante de Pago** de una orden de reserva.
Future<void> generarComprobantePdf({
  required int reservaId,
  required String vehiculo,
  required double alquiler,
  required double garantia,
  required double descuento,
  required double total,
  required String metodo,
  String? detalleMetodo,
  String? cupon,
}) async {
  final doc = pw.Document();
  final ahora = DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  final fecha =
      '${dos(ahora.day)}/${dos(ahora.month)}/${ahora.year} ${dos(ahora.hour)}:${dos(ahora.minute)}';
  String sol(double v) => 'S/ ${v.toStringAsFixed(2)}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _encabezado('COMPROBANTE DE PAGO'),
          pw.SizedBox(height: 12),
          _campo('N° de reserva', '#$reservaId'),
          _campo('Fecha de emisión', fecha),
          _campo('Vehículo', vehiculo),
          _campo('Método de pago', detalleMetodo == null ? metodo : '$metodo ($detalleMetodo)'),
          if (cupon != null) _campo('Cupón aplicado', cupon),
          pw.SizedBox(height: 16),
          pw.Text('Detalle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _campo('Alquiler', sol(alquiler)),
          if (descuento > 0) _campo('Descuento', '- ${sol(descuento)}'),
          _campo('Garantía (depósito reembolsable)', sol(garantia)),
          pw.Divider(),
          _campo('Total pagado', sol(total)),
          pw.Spacer(),
          _pie(),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ---------- helpers de layout ----------
pw.Widget _encabezado(String titulo) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AutoRent Perú',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(titulo, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 1.2),
      ],
    );

pw.Widget _campo(String k, String v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text(k, style: pw.TextStyle(color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );

pw.Widget _pie() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(),
        pw.Text('Documento generado por el Sistema de Alquiler de Vehículos (SAV).',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
