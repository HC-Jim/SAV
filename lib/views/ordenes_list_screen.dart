import 'package:flutter/material.dart';
import '../models/fase_orden.dart';
import '../models/orden_mantenimiento.dart';
import '../services/mantenimiento_service.dart';
import '../widgets/estado_chip.dart';
import 'orden_detail_screen.dart';

/// Buscar orden de mantenimiento (caso de uso incluido tanto por «Generar
/// presupuesto» como por «Ejecutar mantenimiento»). Lista todas las órdenes;
/// al tocar una, según su estado se abre la interfaz de Presupuesto o la de
/// Ejecución de mantenimiento (son pantallas distintas).
class OrdenesListScreen extends StatefulWidget {
  const OrdenesListScreen({super.key});

  @override
  State<OrdenesListScreen> createState() => _OrdenesListScreenState();
}

class _OrdenesListScreenState extends State<OrdenesListScreen> {
  final _svc = MantenimientoService();
  late Future<List<OrdenMantenimiento>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarOrdenes());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar orden de mantenimiento'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: FutureBuilder<List<OrdenMantenimiento>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final ordenes = snap.data ?? [];
          if (ordenes.isEmpty) {
            return const Center(child: Text('No hay órdenes de mantenimiento.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ordenes.length,
            itemBuilder: (context, i) {
              final o = ordenes[i];
              // La fase (Presupuesto o Ejecución) se deduce del estado de la
              // orden y determina qué interfaz de detalle se abre.
              final fase = faseDeEstado(o.estado);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${o.id}')),
                  title: Text(o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}'),
                  subtitle: Text(o.tipoServicio ?? '-'),
                  trailing: EstadoChip(o.estado),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OrdenDetailScreen(ordenId: o.id, fase: fase),
                    ));
                    _cargar();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
