import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import 'pagar_reserva_screen.dart';

/// Lista de reservas del Cliente con las acciones disponibles por estado.
class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});
  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.misReservas());

  Future<void> _abrirPago(Reserva r) async {
    final pagado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PagarReservaScreen(reserva: r)),
    );
    if (pagado == true) _cargar();
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
    if (r.estado == EstadoReserva.porPagar) {
      acciones.add(FilledButton.icon(
        onPressed: () => _abrirPago(r),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Pagar orden de reserva'),
      ));
    }
    return acciones;
  }
}
