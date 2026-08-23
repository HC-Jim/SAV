import 'package:flutter/material.dart';
import '../models/orden_mantenimiento.dart';
import '../services/mantenimiento_service.dart';
import '../widgets/estado_chip.dart';
import 'orden_detail_screen.dart';

class OrdenesListScreen extends StatefulWidget {
  const OrdenesListScreen({super.key});
  @override
  State<OrdenesListScreen> createState() => _OrdenesListScreenState();
}

class _OrdenesListScreenState extends State<OrdenesListScreen> {
  final _svc = MantenimientoService();
  late Future<List<OrdenMantenimiento>> _futuro;
  String _filtro = '';

  static const _estados = [
    '',
    EstadoOrden.pendienteInspeccion,
    EstadoOrden.inspeccionCompleta,
    EstadoOrden.pendienteAutorizacion,
    EstadoOrden.presupuestoAutorizado,
    EstadoOrden.enMantenimiento,
    EstadoOrden.pendienteConformidad,
    EstadoOrden.correccionRequerida,
    EstadoOrden.cerrado,
    EstadoOrden.cerradaPorRechazo,
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() => _futuro = _svc.listarOrdenes(estado: _filtro));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de mantenimiento'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _filtro,
              decoration: const InputDecoration(
                labelText: 'Filtrar por estado',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: _estados
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.isEmpty ? 'Todos' : EstadoOrden.legible(e)),
                      ))
                  .toList(),
              onChanged: (v) {
                _filtro = v ?? '';
                _cargar();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrdenMantenimiento>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _MensajeError('${snap.error}', _cargar);
                }
                final ordenes = snap.data ?? [];
                if (ordenes.isEmpty) {
                  return const Center(child: Text('No hay órdenes para este filtro.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: ordenes.length,
                    itemBuilder: (context, i) {
                      final o = ordenes[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('#${o.id}')),
                          title: Text(o.vehiculo?.descripcion ?? 'Vehículo ${o.vehiculoId}'),
                          subtitle: Text(o.tipoServicio ?? 'Sin tipo de servicio'),
                          trailing: EstadoChip(o.estado),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrdenDetailScreen(ordenId: o.id),
                              ),
                            );
                            _cargar();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _MensajeError(this.mensaje, this.onReintentar);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
