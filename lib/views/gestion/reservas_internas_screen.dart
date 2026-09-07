import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../widgets/visor_comprobantes.dart';

/// Vista interna (Jefe de Logística): consulta de todas las reservas.
/// Solo lectura — las acciones del Cajero viven en sus pantallas dedicadas.
class ReservasInternasScreen extends StatefulWidget {
  const ReservasInternasScreen({super.key});
  @override
  State<ReservasInternasScreen> createState() => _ReservasInternasScreenState();
}

class _ReservasInternasScreenState extends State<ReservasInternasScreen> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarTodas());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: FutureBuilder<List<Reserva>>(
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
            children: lista.map(_card).toList(),
          );
        },
      ),
    );
  }

  Widget _card(Reserva r) {
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
            if (r.montoDevuelto > 0) Text('Devuelto: S/ ${r.montoDevuelto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => VisorComprobantes.abrir(context, reservaId: r.id),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Ver comprobantes'),
            ),
          ],
        ),
      ),
    );
  }
}
