import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../state/auth_controller.dart';

/// Vista interna de todas las reservas.
/// El Cajero además puede procesar pagos, devolución y cancelaciones.
class ReservasInternasScreen extends StatefulWidget {
  const ReservasInternasScreen({super.key});
  @override
  State<ReservasInternasScreen> createState() => _ReservasInternasScreenState();
}

class _ReservasInternasScreenState extends State<ReservasInternasScreen> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarTodas());

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _procesando = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Operación realizada')));
      _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  /// Gestionar Cancelación (Cajero): aplica la regla de 48 h y emite comprobante.
  Future<void> _gestionarCancelacion(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gestionar cancelación'),
        content: const Text(
            'Se aplicará penalidad si faltan menos de 48 h para el inicio, '
            'se devolverá la garantía restante y se emitirá el comprobante. ¿Confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) _ejecutar(() => _svc.gestionarCancelacion(r.id));
  }

  /// Devolver Garantía (Cajero): permite registrar deducciones por daños.
  Future<void> _devolverGarantia(Reserva r) async {
    final ded = TextEditingController(text: '0');
    final datos = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Devolver garantía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Garantía retenida: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: ded,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Deducciones por daños (S/)'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Se devuelve la garantía menos las deducciones y se emite el comprobante.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ded.text.trim()) ?? 0),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );
    if (datos != null) _ejecutar(() => _svc.devolverGarantia(r.id, deducciones: datos));
  }

  /// Emitir Comprobante (Cajero) del pago de alquiler.
  Future<void> _emitirComprobante(Reserva r) async {
    setState(() => _procesando = true);
    try {
      await _svc.emitirComprobante(r.id);
      await _verComprobantes(r, recargar: false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Comprobante emitido')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _verComprobantes(Reserva r, {bool recargar = true}) async {
    if (recargar) setState(() => _procesando = true);
    try {
      final lista = await _svc.comprobantes(r.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Comprobantes · Reserva #${r.id}'),
          content: lista.isEmpty
              ? const Text('Sin comprobantes.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lista
                      .map((c) => Text(
                          '• ${c['tipo'] ?? 'BOLETA'} — S/ ${((c['monto_total'] as num?) ?? 0).toStringAsFixed(2)}'))
                      .toList(),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
      }
    } finally {
      if (recargar && mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCajero = context.watch<AuthController>().usuario?.esCajero ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: Column(
        children: [
          if (_procesando) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<Reserva>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                final lista = snap.data ?? [];
                if (lista.isEmpty) return const Center(child: Text('No hay reservas.'));
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: lista.map((r) => _card(r, esCajero)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Reserva r, bool esCajero) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reserva #${r.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(EstadoReserva.legible(r.estado),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(r.vehiculo != null
                ? '${r.vehiculo!.marca ?? ''} ${r.vehiculo!.modelo ?? ''} (${r.vehiculo!.placa})'.trim()
                : 'Vehículo ${r.vehiculoId ?? '-'}'),
            Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}'),
            const SizedBox(height: 4),
            Text('Total: S/ ${r.montoTotalEstimado.toStringAsFixed(2)}  ·  '
                'Garantía: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
            if (r.penalidad > 0) Text('Penalidad: S/ ${r.penalidad.toStringAsFixed(2)}'),
            if (r.montoDevuelto > 0) Text('Devuelto: S/ ${r.montoDevuelto.toStringAsFixed(2)}'),
            if (esCajero) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _accionesCajero(r)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _accionesCajero(Reserva r) {
    final acciones = <Widget>[];
    final off = _procesando;

    if (r.estado == EstadoReserva.confirmada) {
      acciones.add(FilledButton(
        onPressed: off ? null : () => _ejecutar(() => _svc.pagarAlquiler(r.id)),
        child: const Text('Registrar pago de alquiler'),
      ));
      acciones.add(OutlinedButton(
        onPressed: off ? null : () => _gestionarCancelacion(r),
        child: const Text('Gestionar cancelación'),
      ));
    } else if (r.estado == EstadoReserva.enCurso) {
      acciones.add(FilledButton(
        onPressed: off ? null : () => _devolverGarantia(r),
        child: const Text('Devolver garantía'),
      ));
      acciones.add(OutlinedButton(
        onPressed: off ? null : () => _emitirComprobante(r),
        child: const Text('Emitir comprobante'),
      ));
      acciones.add(OutlinedButton(
        onPressed: off ? null : () => _gestionarCancelacion(r),
        child: const Text('Gestionar cancelación'),
      ));
    } else {
      // FINALIZADA / CANCELADA: solo consulta/emisión de comprobantes.
      if (r.estado == EstadoReserva.finalizada) {
        acciones.add(OutlinedButton(
          onPressed: off ? null : () => _emitirComprobante(r),
          child: const Text('Emitir comprobante'),
        ));
      }
      acciones.add(TextButton(
        onPressed: off ? null : () => _verComprobantes(r),
        child: const Text('Ver comprobantes'),
      ));
    }
    return acciones;
  }
}
