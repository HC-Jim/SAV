import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/alquiler_service.dart';
import 'crear_orden_screen.dart';
import 'estado_vehiculo_screen.dart';

/// Modo de uso de la búsqueda de vehículos (caso de uso «include» Buscar Vehículo).
enum ModoVehiculo {
  /// Elegir un vehículo para crear una orden de mantenimiento.
  crearOrden,

  /// Elegir un vehículo para ver su estado y sus órdenes.
  verEstado,
}

/// «include» Buscar Vehículo: lista la flota con su estado. Según el modo,
/// al tocar un vehículo continúa con "Crear orden" (preseleccionado) o abre
/// la pantalla "Estado del vehículo".
class BuscarVehiculoScreen extends StatefulWidget {
  final ModoVehiculo modo;
  const BuscarVehiculoScreen({super.key, required this.modo});

  @override
  State<BuscarVehiculoScreen> createState() => _BuscarVehiculoScreenState();
}

class _BuscarVehiculoScreenState extends State<BuscarVehiculoScreen> {
  final _svc = AlquilerService();
  late Future<List<Vehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Toda la flota, con su estado (DISPONIBLE / ALQUILADO / EN_MANTENIMIENTO).
  void _cargar() =>
      setState(() => _futuro = _svc.catalogo(soloDisponibles: false));

  String get _titulo => widget.modo == ModoVehiculo.crearOrden
      ? 'Crear orden · elige un vehículo'
      : 'Órdenes · elige un vehículo';

  bool _bloqueadoParaOrden(Vehiculo v) =>
      v.estado == 'ALQUILADO' || v.estado == 'EN_MANTENIMIENTO';

  Future<void> _seleccionar(Vehiculo v) async {
    if (widget.modo == ModoVehiculo.verEstado) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EstadoVehiculoScreen(vehiculo: v)),
      );
      _cargar();
      return;
    }
    // modo crearOrden
    if (_bloqueadoParaOrden(v)) {
      final motivo = v.estado == 'ALQUILADO'
          ? 'El vehículo está alquilado a un cliente.'
          : 'El vehículo ya tiene una orden en curso.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$motivo No se puede crear una orden.')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CrearOrdenScreen(vehiculoPreseleccionado: v)),
    );
    _cargar();
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
      appBar: AppBar(
        title: Text(_titulo),
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
            return const Center(child: Text('No hay vehículos registrados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehiculos.length,
            itemBuilder: (context, i) {
              final v = vehiculos[i];
              final bloqueado =
                  widget.modo == ModoVehiculo.crearOrden && _bloqueadoParaOrden(v);
              return Card(
                child: ListTile(
                  enabled: !bloqueado,
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.descripcion),
                  subtitle: Text('Categoría: ${v.categoria ?? '-'}'),
                  trailing: Chip(
                    label: Text(v.estadoLegible,
                        style: TextStyle(color: _colorEstado(v.estado), fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => _seleccionar(v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
