import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/orden_mantenimiento.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/mantenimiento_service.dart';
import '../state/auth_controller.dart';
import '../widgets/estado_chip.dart';
import 'dialogs/inspeccion_dialog.dart';
import 'dialogs/requerimiento_dialog.dart';
import 'dialogs/presupuesto_dialog.dart';
import 'dialogs/informe_dialog.dart';
import 'dialogs/decision_dialog.dart';

/// Detalle de una Orden de Mantenimiento con las acciones disponibles
/// según el rol del usuario y el estado actual de la orden.
class OrdenDetailScreen extends StatefulWidget {
  final int ordenId;
  const OrdenDetailScreen({super.key, required this.ordenId});

  @override
  State<OrdenDetailScreen> createState() => _OrdenDetailScreenState();
}

class _OrdenDetailScreenState extends State<OrdenDetailScreen> {
  final _svc = MantenimientoService();
  late Future<OrdenMantenimiento> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() =>
      setState(() => _futuro = _svc.obtenerOrden(widget.ordenId));

  /// Ejecuta una acción de servicio, muestra el error si falla y recarga.
  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _procesando = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Acción realizada')));
      _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${widget.ordenId}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: FutureBuilder<OrdenMantenimiento>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final o = snap.data!;
          return Column(
            children: [
              Expanded(child: _detalle(o)),
              if (_procesando) const LinearProgressIndicator(),
              _barraAcciones(o, usuario),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Vista de detalle ----------------
  Widget _detalle(OrdenMantenimiento o) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _cardInfo(o),
        if (o.inspecciones.isNotEmpty) _cardInspeccion(o.inspecciones.last),
        if (o.requerimientos.isNotEmpty) _cardRequerimientos(o),
        if (o.presupuestos.isNotEmpty) _cardPresupuestos(o),
        if (o.informes.isNotEmpty) _cardInforme(o.informes.last),
        if (o.actaEntrega != null) _cardActa(o.actaEntrega!),
      ],
    );
  }

  Widget _cardInfo(OrdenMantenimiento o) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  EstadoChip(o.estado),
                ],
              ),
              const SizedBox(height: 8),
              _fila('Tipo de servicio', o.tipoServicio ?? '-'),
              if (o.descripcion != null && o.descripcion!.isNotEmpty)
                _fila('Descripción', o.descripcion!),
              _fila('Creada', _fecha(o.fechaCreacion)),
              if (o.duracionMinutos != null)
                _fila('Duración mano de obra', '${o.duracionMinutos} min'),
            ],
          ),
        ),
      );

  Widget _cardInspeccion(Inspeccion i) => _card(
        'Inspección',
        Icons.search,
        [
          _fila('Diagnóstico', i.diagnostico ?? '-'),
          _fila('Resultado', i.resultado ?? '-'),
          _fila('Necesita repuestos', i.necesitaRepuestos ? 'Sí' : 'No'),
          if (i.kilometrajeLectura != null)
            _fila('Kilometraje', '${i.kilometrajeLectura} km'),
          if (i.nivelCombustible != null) _fila('Combustible', i.nivelCombustible!),
          if (i.observaciones != null && i.observaciones!.isNotEmpty)
            _fila('Observaciones', i.observaciones!),
        ],
      );

  Widget _cardRequerimientos(OrdenMantenimiento o) => _card(
        'Requerimientos de repuestos',
        Icons.list_alt,
        o.requerimientos.map((r) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Requerimiento #${r.id}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Chip(
                    label: Text(r.estado),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: r.estado == 'COMPRADO'
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                  ),
                ],
              ),
              ...r.items.map((it) => Text(
                  '• ${it.nombre}  x${it.cantidad}  (S/ ${it.precioUnitario.toStringAsFixed(2)})')),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      );

  Widget _cardPresupuestos(OrdenMantenimiento o) => _card(
        'Presupuesto',
        Icons.request_quote_outlined,
        o.presupuestos.map((p) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fila('Repuestos', 'S/ ${p.costoRepuestos.toStringAsFixed(2)}'),
              _fila('Mano de obra', 'S/ ${p.costoManoObra.toStringAsFixed(2)}'),
              _fila('Total', 'S/ ${p.total.toStringAsFixed(2)}'),
              _fila('Estado', p.estado),
              if (p.motivoRechazo != null && p.motivoRechazo!.isNotEmpty)
                _fila('Motivo rechazo', p.motivoRechazo!),
              const Divider(),
            ],
          );
        }).toList(),
      );

  Widget _cardInforme(InformeTecnico inf) => _card(
        'Informe técnico',
        Icons.description_outlined,
        [
          _fila('Trabajos', inf.trabajosRealizados ?? '-'),
          _fila('Pruebas', inf.resultadosPruebas ?? '-'),
          if (inf.conforme != null)
            _fila('Conforme', inf.conforme! ? 'Sí' : 'No'),
          if (inf.motivoCorreccion != null && inf.motivoCorreccion!.isNotEmpty)
            _fila('Motivo corrección', inf.motivoCorreccion!),
        ],
      );

  Widget _cardActa(Map<String, dynamic> acta) => _card(
        'Acta de entrega',
        Icons.verified_outlined,
        [Text(acta['contenido']?.toString() ?? '-')],
      );

  Widget _card(String titulo, IconData icono, List<Widget> hijos) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icono, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              ...hijos,
            ],
          ),
        ),
      );

  Widget _fila(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(k, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  String _fecha(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }

  // ---------------- Barra de acciones contextuales ----------------
  Widget _barraAcciones(OrdenMantenimiento o, Usuario u) {
    final acciones = _accionesDisponibles(o, u);
    if (acciones.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No hay acciones disponibles para tu rol en este estado.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
        ),
        child: Wrap(spacing: 8, runSpacing: 8, children: acciones),
      ),
    );
  }

  List<Widget> _accionesDisponibles(OrdenMantenimiento o, Usuario u) {
    if (o.esFinal) return [];
    final acciones = <Widget>[];
    final e = o.estado;

    if (u.esMecanico) {
      if (e == EstadoOrden.pendienteInspeccion || e == EstadoOrden.inspeccionPostergada) {
        acciones.add(_btn('Registrar inspección', Icons.search, () async {
          final datos = await mostrarInspeccionDialog(context);
          if (datos != null) _ejecutar(() => _svc.registrarInspeccion(o.id, datos));
        }));
      }
      if (e == EstadoOrden.inspeccionCompleta) {
        acciones.add(_btn('Requerimiento repuestos', Icons.add_shopping_cart, () async {
          final items = await mostrarRequerimientoDialog(context, _svc);
          if (items != null && items.isNotEmpty) {
            _ejecutar(() => _svc.crearRequerimiento(o.id, items));
          }
        }));
        acciones.add(_btn('Generar presupuesto', Icons.request_quote, () async {
          final datos = await mostrarPresupuestoDialog(context, _svc);
          if (datos != null) _ejecutar(() => _svc.generarPresupuesto(o.id, datos));
        }));
        acciones.add(_btn('Iniciar (sin hallazgos)', Icons.play_arrow, () {
          _ejecutar(() => _svc.iniciarMantenimiento(o.id));
        }, tonal: true));
      }
      if (e == EstadoOrden.presupuestoAutorizado) {
        acciones.add(_btn('Iniciar mantenimiento', Icons.play_arrow, () {
          _ejecutar(() => _svc.iniciarMantenimiento(o.id));
        }));
      }
      if (e == EstadoOrden.enMantenimiento) {
        if (o.horaFinMant == null) {
          acciones.add(_btn('Finalizar mantenimiento', Icons.stop, () {
            _ejecutar(() => _svc.finalizarMantenimiento(o.id));
          }, tonal: true));
        }
        acciones.add(_btn('Generar informe', Icons.description, () async {
          final datos = await mostrarInformeDialog(context);
          if (datos != null) _ejecutar(() => _svc.generarInforme(o.id, datos));
        }));
      }
      if (e == EstadoOrden.correccionRequerida) {
        acciones.add(_btn('Corregir informe', Icons.description, () async {
          final datos = await mostrarInformeDialog(context);
          if (datos != null) _ejecutar(() => _svc.generarInforme(o.id, datos));
        }));
      }
    }

    if (u.esJefe) {
      if (e == EstadoOrden.inspeccionCompleta || e == EstadoOrden.pendienteAutorizacion) {
        for (final r in o.requerimientosPendientes) {
          acciones.add(_btn('Comprar req. #${r.id}', Icons.shopping_cart_checkout, () {
            _ejecutar(() => _svc.comprarRepuestos(r.id));
          }, tonal: true));
        }
      }
      if (e == EstadoOrden.pendienteAutorizacion && o.presupuestoPendiente != null) {
        final p = o.presupuestoPendiente!;
        acciones.add(_btn('Autorizar presupuesto', Icons.check_circle, () {
          _ejecutar(() => _svc.decidirPresupuesto(p.id, true));
        }));
        acciones.add(_btn('Rechazar presupuesto', Icons.cancel, () async {
          final motivo = await mostrarMotivoDialog(context, 'Rechazar presupuesto');
          if (motivo != null) _ejecutar(() => _svc.decidirPresupuesto(p.id, false, motivo: motivo));
        }, peligro: true));
      }
      if (e == EstadoOrden.pendienteConformidad) {
        acciones.add(_btn('Dar conformidad y cerrar', Icons.verified, () {
          _ejecutar(() => _svc.decidirConformidad(o.id, true));
        }));
        acciones.add(_btn('Rechazar conformidad', Icons.error_outline, () async {
          final motivo = await mostrarMotivoDialog(context, 'Rechazar conformidad');
          if (motivo != null) _ejecutar(() => _svc.decidirConformidad(o.id, false, motivo: motivo));
        }, peligro: true));
      }
    }
    return acciones;
  }

  Widget _btn(String texto, IconData icono, VoidCallback onTap,
      {bool tonal = false, bool peligro = false}) {
    if (peligro) {
      return OutlinedButton.icon(
        onPressed: _procesando ? null : onTap,
        icon: Icon(icono, color: Colors.red),
        label: Text(texto, style: const TextStyle(color: Colors.red)),
      );
    }
    if (tonal) {
      return FilledButton.tonalIcon(
          onPressed: _procesando ? null : onTap, icon: Icon(icono), label: Text(texto));
    }
    return FilledButton.icon(
        onPressed: _procesando ? null : onTap, icon: Icon(icono), label: Text(texto));
  }
}
