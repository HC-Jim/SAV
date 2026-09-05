import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/orden_mantenimiento.dart';

/// Genera y abre (vista previa / guardar) el documento PDF del **Presupuesto**.
Future<void> generarPresupuestoPdf(OrdenMantenimiento o) async {
  final doc = pw.Document();
  final p = o.presupuestos.isNotEmpty ? o.presupuestos.last : null;
  final items = o.requerimientos.isEmpty
      ? const <RepuestoItem>[]
      : o.requerimientos.last.items;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _encabezado('PRESUPUESTO DE MANTENIMIENTO'),
          pw.SizedBox(height: 12),
          _campo('Orden', '#${o.id}'),
          _campo('Vehículo', o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}'),
          _campo('Tipo de servicio', o.tipoServicio ?? '-'),
          pw.SizedBox(height: 16),
          pw.Text('Repuestos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (items.isEmpty)
            pw.Text('Sin repuestos.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Descripción', 'Cant.', 'P. Unit. (S/)', 'Subtotal (S/)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              data: items
                  .map((it) => [
                        it.nombre,
                        '${it.cantidad}',
                        it.precioUnitario.toStringAsFixed(2),
                        (it.precioUnitario * it.cantidad).toStringAsFixed(2),
                      ])
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          _total('Repuestos', p?.costoRepuestos ?? 0),
          _total('Mano de obra', p?.costoManoObra ?? 0),
          pw.Divider(),
          _total('TOTAL', p?.total ?? 0, negrita: true),
          pw.SizedBox(height: 12),
          _campo('Estado', p?.estado ?? '-'),
          pw.Spacer(),
          _pie(),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

/// Genera y abre el documento PDF del **Informe Técnico**.
Future<void> generarInformePdf(OrdenMantenimiento o) async {
  final doc = pw.Document();
  final inf = o.informes.isNotEmpty ? o.informes.last : null;
  final insp = o.inspecciones.isNotEmpty ? o.inspecciones.last : null;
  final p = o.presupuestos.isNotEmpty ? o.presupuestos.last : null;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        _encabezado('INFORME TÉCNICO'),
        pw.SizedBox(height: 12),
        _campo('Orden', '#${o.id}'),
        _campo('Vehículo', o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}'),
        _campo('Tipo de servicio', o.tipoServicio ?? '-'),
        _campo('Descripción de la actividad', o.descripcion ?? '-'),
        pw.SizedBox(height: 16),

        pw.Text('Ejecución del mantenimiento',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _campo('Mantenimiento iniciado', _fecha(o.horaInicioMant)),
        _campo('Mantenimiento finalizado', _fecha(o.horaFinMant)),
        if (o.duracionMinutos != null) _campo('Duración', '${o.duracionMinutos} min'),
        if (o.observacionEjecucion != null && o.observacionEjecucion!.isNotEmpty)
          _campo('Observación de ejecución', o.observacionEjecucion!),
        pw.SizedBox(height: 16),

        if (insp != null) ...[
          pw.Text('Inspección', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _campo('Diagnóstico', insp.diagnostico ?? '-'),
          _campo('Resultado', insp.resultado ?? '-'),
          pw.SizedBox(height: 16),
        ],

        pw.Text('Trabajos y pruebas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _campo('Trabajos realizados', inf?.trabajosRealizados ?? '-'),
        _campo('Pruebas de funcionamiento', inf?.resultadosPruebas ?? '-'),
        if (inf?.conforme != null) _campo('Conforme', inf!.conforme! ? 'Sí' : 'No'),
        if (inf?.motivoCorreccion != null && inf!.motivoCorreccion!.isNotEmpty)
          _campo('Motivo de corrección', inf.motivoCorreccion!),
        pw.SizedBox(height: 16),

        pw.Text('Gastos (presupuesto)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _total('Repuestos', p?.costoRepuestos ?? 0),
        _total('Mano de obra', p?.costoManoObra ?? 0),
        pw.Divider(),
        _total('TOTAL', p?.total ?? 0, negrita: true),
        pw.SizedBox(height: 24),
        _pie(),
      ],
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

/// Fecha ISO → 'dd/mm/aaaa hh:mm' (o '-').
String _fecha(String? iso) {
  if (iso == null) return '-';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
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

pw.Widget _total(String k, double v, {bool negrita = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k,
              style: pw.TextStyle(
                  fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
                  fontSize: negrita ? 14 : 11)),
          pw.Text('S/ ${v.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
                  fontSize: negrita ? 14 : 11)),
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
