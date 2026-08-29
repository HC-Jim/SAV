import 'package:flutter/material.dart';
import '../models/fase_orden.dart';
import '../models/orden_mantenimiento.dart';
import '../models/vehiculo.dart';
import '../services/mantenimiento_service.dart';
import 'orden_detail_screen.dart';

/// Estado de un vehículo: su estado actual y las órdenes de mantenimiento
/// asociadas. Se llega desde los módulos "Presupuesto" / "Informe Técnico".
class EstadoVehiculoScreen extends StatefulWidget {
  final Vehiculo vehiculo;
  final FaseOrden fase;
  const EstadoVehiculoScreen({super.key, required this.vehiculo, required this.fase});

  @override
  State<EstadoVehiculoScreen> createState() => _EstadoVehiculoScreenState();
}

class _EstadoVehiculoScreenState extends State<EstadoVehiculoScreen> {
  final _svc = MantenimientoService();
  late Future<List<OrdenMantenimiento>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Órdenes de este vehículo (filtra la lista general por vehiculo_id).
  void _cargar() => setState(() => _futuro = _svc.listarOrdenes().then(
        (todas) => todas.where((o) => o.vehiculoId == widget.vehiculo.id).toList(),
      ));

  @override
  Widget build(BuildContext context) {
    final v = widget.vehiculo;
    final alquilado = v.estado == 'ALQUILADO';

    return Scaffold(
      appBar: AppBar(
        title: Text('Estado · ${v.placa}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Ficha del vehículo ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(v.descripcion,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Chip(label: Text(v.estadoLegible)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('SKU: ${v.sku ?? '-'}  ·  Categoría: ${v.categoria ?? '-'}'),
                  if (v.kilometraje != null) Text('Kilometraje: ${v.kilometraje} km'),
                  if (v.fechaProximoMantenimiento != null)
                    Text('Próx. mantenimiento: ${v.fechaProximoMantenimiento}'),
                ],
              ),
            ),
          ),

          // --- Aviso si el cliente lo tiene ---
          if (alquilado)
            const Card(
              color: Color(0xFFFDEFD8),
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('En uso por un cliente'),
                subtitle: Text(
                    'El vehículo está reservado/alquilado. No se puede crear una orden de mantenimiento hasta su devolución.'),
              ),
            ),

          const SizedBox(height: 8),
          const Text('Órdenes de mantenimiento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          // --- Órdenes del vehículo ---
          FutureBuilder<List<OrdenMantenimiento>>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) return Text('${snap.error}');
              final ordenes = snap.data ?? [];
              if (ordenes.isEmpty) {
                return const Card(
                  child: ListTile(title: Text('Este vehículo no tiene órdenes.')),
                );
              }
              return Column(
                children: ordenes
                    .map((o) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('#${o.id}')),
                            title: Text(o.tipoServicio ?? 'Orden #${o.id}'),
                            subtitle: Text(EstadoOrden.legible(o.estado)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrdenDetailScreen(ordenId: o.id, fase: widget.fase),
                                ),
                              );
                              _cargar();
                            },
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
