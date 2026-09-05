import 'package:flutter/material.dart';
import '../models/fase_orden.dart';
import '../models/orden_mantenimiento.dart';
import '../services/mantenimiento_service.dart';
import '../widgets/estado_chip.dart';
import 'orden_detail_screen.dart';

/// Lista de órdenes de una fase (Presupuesto o Ejecución). Al tocar una orden
/// se abre su detalle en esa fase.
class OrdenesListScreen extends StatefulWidget {
  final FaseOrden fase;
  const OrdenesListScreen({super.key, required this.fase});

  @override
  State<OrdenesListScreen> createState() => _OrdenesListScreenState();
}

class _OrdenesListScreenState extends State<OrdenesListScreen> {
  final _svc = MantenimientoService();
  late Future<List<OrdenMantenimiento>> _futuro;

  bool get _esPresupuesto => widget.fase == FaseOrden.presupuesto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Solo las órdenes que están en la fase indicada.
  void _cargar() => setState(() => _futuro = _svc.listarOrdenes().then(
        (todas) => todas.where((o) => faseDeEstado(o.estado) == widget.fase).toList(),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esPresupuesto ? 'Presupuesto' : 'Ejecución de mantenimiento'),
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
            return Center(
                child: Text(_esPresupuesto
                    ? 'No hay órdenes en fase de presupuesto.'
                    : 'No hay órdenes en fase de ejecución.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ordenes.length,
            itemBuilder: (context, i) {
              final o = ordenes[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${o.id}')),
                  title: Text(o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}'),
                  subtitle: Text(o.tipoServicio ?? '-'),
                  trailing: EstadoChip(o.estado),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OrdenDetailScreen(ordenId: o.id, fase: widget.fase),
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
