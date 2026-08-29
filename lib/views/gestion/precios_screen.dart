import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehiculo.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../state/auth_controller.dart';

/// Catálogo de Precios: «include» Buscar Vehículo. Cualquier usuario puede
/// consultar los precios (por día) de un vehículo; solo el Administrador puede
/// editarlos.
class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});
  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final _alquiler = AlquilerService();
  final _gestion = GestionService();
  late Future<List<Vehiculo>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _alquiler.catalogo(soloDisponibles: false));

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.watch<AuthController>().usuario?.esAdministrador ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de precios'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar vehículo',
                hintText: 'Placa, marca o modelo…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
          ),
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
                    : todos.where((v) => v.descripcion.toLowerCase().contains(_filtro)).toList();
                if (lista.isEmpty) return const Center(child: Text('Sin vehículos.'));
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: lista.map((v) => _card(v, esAdmin)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Vehiculo v, bool esAdmin) {
    return Card(
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (esAdmin)
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editarPrecio(v)),
              ],
            ),
            Text('SKU: ${v.sku ?? '-'}  ·  Categoría: ${v.categoria ?? '-'}  ·  ${v.estadoLegible}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text('Regular: S/ ${v.precioRegular.toStringAsFixed(2)} / día'),
            Text('Normal: S/ ${v.precioNormal.toStringAsFixed(2)} / día'),
            Text('Campaña: S/ ${v.precioCampania.toStringAsFixed(2)} / día  '
                '(desde ${v.diasMinCampania} días)'),
          ],
        ),
      ),
    );
  }

  Future<void> _editarPrecio(Vehiculo v) async {
    final regular = TextEditingController(text: v.precioRegular.toString());
    final normal = TextEditingController(text: v.precioNormal.toString());
    final campania = TextEditingController(text: v.precioCampania.toString());
    final diasMin = TextEditingController(text: v.diasMinCampania.toString());

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Precio · ${v.placa}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(regular, 'Precio regular (S/ por día)'),
            _campo(normal, 'Precio normal (S/ por día)'),
            _campo(campania, 'Precio campaña (S/ por día)'),
            _campo(diasMin, 'Días mínimos para campaña'),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('El precio regular debe ser mayor al normal.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'precio_regular': double.tryParse(regular.text.trim()) ?? 0,
              'precio_normal': double.tryParse(normal.text.trim()) ?? 0,
              'precio_campania': double.tryParse(campania.text.trim()) ?? 0,
              'dias_min_campania': int.tryParse(diasMin.text.trim()) ?? 7,
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (datos != null) {
      try {
        await _gestion.actualizarPrecioVehiculo(v.id, datos);
        if (mounted) _cargar();
      } on ApiException catch (e) {
        _snack(e.mensaje);
      }
    }
  }

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
