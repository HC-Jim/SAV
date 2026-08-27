import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/alquiler_service.dart';

/// Lista de vehículos **reutilizable e idéntica**. Se usa en:
/// - Órdenes de mantenimiento (Jefe / Mecánico) → estado y órdenes del vehículo
/// - Catálogo de vehículos → detalle
/// - Gestión de vehículos (Administrador) → editar / eliminar
///
/// El destino al tocar un vehículo lo define quien la llama (`onSeleccionar`).
class ListaVehiculosScreen extends StatefulWidget {
  final String titulo;
  final Future<void> Function(BuildContext context, Vehiculo vehiculo) onSeleccionar;

  /// Botón flotante opcional (p. ej. "agregar vehículo" en Gestión).
  final Future<void> Function(BuildContext context)? onAgregar;

  const ListaVehiculosScreen({
    super.key,
    required this.titulo,
    required this.onSeleccionar,
    this.onAgregar,
  });

  @override
  State<ListaVehiculosScreen> createState() => _ListaVehiculosScreenState();
}

class _ListaVehiculosScreenState extends State<ListaVehiculosScreen> {
  final _svc = AlquilerService();
  late Future<List<Vehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() =>
      setState(() => _futuro = _svc.catalogo(soloDisponibles: false));

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
        title: Text(widget.titulo),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      floatingActionButton: widget.onAgregar == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await widget.onAgregar!(context);
                _cargar();
              },
              child: const Icon(Icons.add),
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
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.descripcion),
                  subtitle: Text(
                      'SKU: ${v.sku ?? '-'}  ·  Categoría: ${v.categoria ?? '-'}'),
                  trailing: Chip(
                    label: Text(v.estadoLegible,
                        style: TextStyle(color: _colorEstado(v.estado), fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () async {
                    await widget.onSeleccionar(context, v);
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
