import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/alquiler_service.dart';

/// «include» **Buscar Vehículo** — componente reutilizable e idéntico en toda la app.
///
/// Muestra un campo con el vehículo elegido y, al tocarlo, abre el mismo
/// buscador (lista de la flota con su estado) sin importar desde dónde se
/// llame (Crear Orden, Cotización, Seguros...). Así el caso incluido se ve
/// exactamente igual en cada lugar.
class SelectorVehiculo extends StatelessWidget {
  final Vehiculo? value;
  final ValueChanged<Vehiculo> onChanged;

  /// Si es true, solo ofrece vehículos disponibles (para reservar/cotizar/OM).
  final bool soloDisponibles;
  final String label;

  const SelectorVehiculo({
    super.key,
    required this.value,
    required this.onChanged,
    this.soloDisponibles = false,
    this.label = 'Vehículo',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegido = await Navigator.of(context).push<Vehiculo>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _BuscadorVehiculoScreen(soloDisponibles: soloDisponibles),
          ),
        );
        if (elegido != null) onChanged(elegido);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.directions_car),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          value?.descripcion ?? 'Buscar vehículo…',
          style: TextStyle(
            color: value == null ? Colors.black54 : Colors.black,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Buscador a pantalla completa (lista + filtro por texto). Rendering único
/// del caso «include» Buscar Vehículo.
class _BuscadorVehiculoScreen extends StatefulWidget {
  final bool soloDisponibles;
  const _BuscadorVehiculoScreen({required this.soloDisponibles});

  @override
  State<_BuscadorVehiculoScreen> createState() => _BuscadorVehiculoScreenState();
}

class _BuscadorVehiculoScreenState extends State<_BuscadorVehiculoScreen> {
  final _svc = AlquilerService();
  late Future<List<Vehiculo>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _futuro = _svc.catalogo(soloDisponibles: widget.soloDisponibles);
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'DISPONIBLE':
        return Colors.green.shade700;
      case 'ALQUILADO':
        return Colors.orange.shade800;
      case 'EN_MANTENIMIENTO':
        return Colors.blueGrey;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar vehículo')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Placa, marca o modelo…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Vehiculo>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('${snap.error}'));
                  final todos = snap.data ?? [];
                  final lista = _filtro.isEmpty
                      ? todos
                      : todos
                          .where((v) => v.descripcion.toLowerCase().contains(_filtro))
                          .toList();
                  if (lista.isEmpty) {
                    return const Center(child: Text('Sin vehículos.'));
                  }
                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final v = lista[i];
                      return ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text(v.descripcion),
                        subtitle: Text('Categoría: ${v.categoria ?? '-'}'),
                        trailing: Chip(
                          label: Text(v.estadoLegible,
                              style: TextStyle(
                                  color: _colorEstado(v.estado), fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () => Navigator.pop(context, v),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
