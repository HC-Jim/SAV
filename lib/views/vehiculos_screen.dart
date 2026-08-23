import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/mantenimiento_service.dart';
import 'crear_orden_screen.dart';

/// Vehículos con mantenimiento vencido/próximo (paso "Revisar fechas").
class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});
  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  final _svc = MantenimientoService();
  late Future<List<Vehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.vehiculosPorMantener());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos por mantener'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: FutureBuilder<List<Vehiculo>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final vehiculos = snap.data ?? [];
          if (vehiculos.isEmpty) {
            return const Center(child: Text('Todos los vehículos están al día.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehiculos.length,
            itemBuilder: (context, i) {
              final v = vehiculos[i];
              final enMant = v.estado == 'EN_MANTENIMIENTO';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.descripcion),
                  subtitle: Text(
                    'Próx. mant.: ${v.fechaProximoMantenimiento ?? '-'}'
                    '${v.kilometraje != null ? '  ·  ${v.kilometraje} km' : ''}',
                  ),
                  trailing: enMant
                      ? const Chip(label: Text('En mantenimiento'))
                      : FilledButton.tonal(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CrearOrdenScreen(vehiculoPreseleccionado: v),
                              ),
                            );
                            _cargar();
                          },
                          child: const Text('Crear orden'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
