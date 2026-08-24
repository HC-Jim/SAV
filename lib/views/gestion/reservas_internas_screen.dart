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

  Future<void> _confirmarCancelar(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text(
            'Se aplicará penalidad si faltan menos de 48 h para el inicio. ¿Confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) _ejecutar(() => _svc.cancelar(r.id));
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
            if (esCajero && !r.esFinal) ...[
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
    if (r.estado == EstadoReserva.pendientePago) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.pagarGarantia(r.id)),
        child: const Text('Registrar pago de garantía'),
      ));
    }
    if (r.estado == EstadoReserva.confirmada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.pagarAlquiler(r.id)),
        child: const Text('Registrar pago y devolución'),
      ));
      acciones.add(OutlinedButton(
        onPressed: _procesando ? null : () => _confirmarCancelar(r),
        child: const Text('Cancelar'),
      ));
    }
    return acciones;
  }
}
