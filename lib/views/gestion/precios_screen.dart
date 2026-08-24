import 'package:flutter/material.dart';
import '../../models/catalogo_precio.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Catálogo de Precios (Administrador): precio regular / normal / campaña por categoría.
class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});
  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final _svc = GestionService();
  late Future<List<CatalogoPrecio>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarPrecios());

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _guardar(CatalogoPrecio? p, Map<String, dynamic> datos) async {
    try {
      if (p == null) {
        await _svc.crearPrecio(datos);
      } else {
        await _svc.actualizarPrecio(p.id, datos);
      }
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  Future<void> _eliminar(CatalogoPrecio p) async {
    try {
      await _svc.eliminarPrecio(p.id);
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de precios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CatalogoPrecio>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final lista = snap.data ?? [];
          if (lista.isEmpty) return const Center(child: Text('Sin precios registrados.'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: lista.map(_card).toList(),
          );
        },
      ),
    );
  }

  Widget _card(CatalogoPrecio p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.categoria, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirForm(p)),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _eliminar(p)),
                ]),
              ],
            ),
            if (p.descripcion != null && p.descripcion!.isNotEmpty)
              Text(p.descripcion!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text('Regular: S/ ${p.precioRegular.toStringAsFixed(2)}'),
            Text('Normal: S/ ${p.precioNormal.toStringAsFixed(2)}'),
            Text('Campaña: S/ ${p.precioCampania.toStringAsFixed(2)}  '
                '(desde ${p.diasMinCampania} días)'),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirForm(CatalogoPrecio? p) async {
    final categoria = TextEditingController(text: p?.categoria ?? '');
    final descripcion = TextEditingController(text: p?.descripcion ?? '');
    final regular = TextEditingController(text: p?.precioRegular.toString() ?? '');
    final normal = TextEditingController(text: p?.precioNormal.toString() ?? '');
    final campania = TextEditingController(text: p?.precioCampania.toString() ?? '');
    final diasMin = TextEditingController(text: p?.diasMinCampania.toString() ?? '7');

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p == null ? 'Nuevo precio' : 'Editar precio'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(categoria, 'Categoría'),
            _campo(descripcion, 'Descripción'),
            _campo(regular, 'Precio regular (S/)', numero: true),
            _campo(normal, 'Precio normal (S/)', numero: true),
            _campo(campania, 'Precio campaña (S/)', numero: true),
            _campo(diasMin, 'Días mínimos para campaña', numero: true),
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
              'categoria': categoria.text.trim(),
              'descripcion': descripcion.text.trim(),
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
    if (datos != null) _guardar(p, datos);
  }

  Widget _campo(TextEditingController c, String label, {bool numero = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: numero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
