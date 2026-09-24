import 'package:flutter/material.dart';
import '../models/orden_mantenimiento.dart';
import '../services/mantenimiento_service.dart';

/// Buscar Orden de Mantenimiento — consulta de las órdenes registradas.
class BuscarOrdenScreen extends StatefulWidget {
  const BuscarOrdenScreen({super.key});
  @override
  State<BuscarOrdenScreen> createState() => _BuscarOrdenScreenState();
}

class _BuscarOrdenScreenState extends State<BuscarOrdenScreen> {
  final _svc = MantenimientoService();
  late Future<List<OrdenMantenimiento>> _futuro;
  String _filtro = '';

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar orden',
                hintText: 'N° de orden, vehículo, tipo o estado…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrdenMantenimiento>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                final todas = snap.data ?? [];
                final lista = _filtro.isEmpty
                    ? todas
                    : todas.where((o) => (
                          '#${o.id} ${o.vehiculoDesc} ${o.tipoNombre} ${o.estadoLegible}')
                        .toLowerCase()
                        .contains(_filtro)).toList();
                if (lista.isEmpty) {
                  return const Center(child: Text('Sin órdenes de mantenimiento.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: lista.map(_card).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(OrdenMantenimiento o) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.build_outlined),
        title: Text('Orden #${o.id}  ·  ${o.tipoNombre}'),
        subtitle: Text('${o.vehiculoDesc}\n'
            'Mecánico: ${o.mecanicoNombre}  ·  Estado: ${o.estadoLegible}\n'
            '${(o.indicaciones != null && o.indicaciones!.isNotEmpty) ? 'Indicaciones: ${o.indicaciones}' : ''}'),
        isThreeLine: true,
      ),
    );
  }
}
