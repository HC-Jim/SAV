import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Catálogo de Precios (Administrador): muestra los vehículos y permite editar
/// el precio de cada uno (regular / normal / campaña). Muestra su estado.
class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});
  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final _svc = GestionService();
  late Future<List<Vehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarVehiculos());

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de precios')),
      body: FutureBuilder<List<Vehiculo>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final lista = snap.data ?? [];
          if (lista.isEmpty) return const Center(child: Text('Sin vehículos.'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: lista.map(_card).toList(),
          );
        },
      ),
    );
  }

  Widget _card(Vehiculo v) {
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
                  child: Text('${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editarPrecio(v)),
              ],
            ),
            Text('SKU: ${v.sku ?? '-'}  ·  Categoría: ${v.categoria ?? '-'}  ·  ${v.estadoLegible}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text('Regular: S/ ${v.precioRegular.toStringAsFixed(2)}'),
            Text('Normal: S/ ${v.precioNormal.toStringAsFixed(2)}'),
            Text('Campaña: S/ ${v.precioCampania.toStringAsFixed(2)}  '
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
            _campo(regular, 'Precio regular (S/)'),
            _campo(normal, 'Precio normal (S/)'),
            _campo(campania, 'Precio campaña (S/)'),
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
        await _svc.actualizarPrecioVehiculo(v.id, datos);
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
