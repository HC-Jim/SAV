import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';

/// Vista interna de todas las reservas (Jefe / Cajero / Asesor de Ventas).
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
            children: lista
                .map((r) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('#${r.id}')),
                        title: Text(r.vehiculo != null
                            ? '${r.vehiculo!.marca ?? ''} ${r.vehiculo!.modelo ?? ''} (${r.vehiculo!.placa})'.trim()
                            : 'Vehículo ${r.vehiculoId}'),
                        subtitle: Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}\n'
                            'Total: S/ ${r.montoTotalEstimado.toStringAsFixed(2)}  ·  '
                            'Garantía: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
                        isThreeLine: true,
                        trailing: Text(EstadoReserva.legible(r.estado),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
