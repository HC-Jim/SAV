import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/alquiler_service.dart';
import 'detalle_vehiculo_screen.dart';

/// Catálogo de vehículos disponibles para reservar (Cliente).
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _svc = AlquilerService();
  late Future<List<Vehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.catalogo(soloDisponibles: true));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de vehículos'),
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
            return const Center(child: Text('No hay vehículos disponibles.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehiculos.length,
            itemBuilder: (context, i) {
              final v = vehiculos[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('${v.marca ?? ''} ${v.modelo ?? ''}'.trim()),
                  subtitle: Text('${v.placa}  ·  ${v.anio ?? ''}  ·  ${v.color ?? ''}\n'
                      'Tarifa: S/ ${(v.tarifaDiaria ?? 0).toStringAsFixed(2)} /día'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final creada = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => DetalleVehiculoScreen(vehiculo: v),
                      ),
                    );
                    if (creada == true && mounted) _cargar();
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
