import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';

/// Lista de reservas del Cliente con las acciones disponibles por estado.
class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});
  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.misReservas());

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
            'Se aplicará penalidad si faltan menos de 48 h para el inicio.\n'
            '¿Confirmas la cancelación?'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
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
                final reservas = snap.data ?? [];
                if (reservas.isEmpty) {
                  return const Center(child: Text('Aún no tienes reservas.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reservas.length,
                  itemBuilder: (context, i) => _card(reservas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Reserva r) {
    final v = r.vehiculo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserva #${r.id}  ·  ${EstadoReserva.legible(r.estado)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(v != null ? '${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})'.trim() : 'Vehículo ${r.vehiculoId}'),
            Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}'),
            const SizedBox(height: 6),
            Text('Total estimado: S/ ${r.montoTotalEstimado.toStringAsFixed(2)}'),
            Text('Garantía: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
            if (r.penalidad > 0) Text('Penalidad: S/ ${r.penalidad.toStringAsFixed(2)}'),
            if (r.montoDevuelto > 0) Text('Devuelto: S/ ${r.montoDevuelto.toStringAsFixed(2)}'),
            if (r.motivoCancelacion != null) Text('Motivo: ${r.motivoCancelacion}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _acciones(r)),
          ],
        ),
      ),
    );
  }

  List<Widget> _acciones(Reserva r) {
    if (r.esFinal) return [];
    final acciones = <Widget>[];
    if (r.estado == EstadoReserva.confirmada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.pagarAlquiler(r.id)),
        child: const Text('Pagar alquiler y finalizar'),
      ));
      acciones.add(OutlinedButton(
        onPressed: _procesando ? null : () => _confirmarCancelar(r),
        child: const Text('Cancelar'),
      ));
    }
    return acciones;
  }
}
