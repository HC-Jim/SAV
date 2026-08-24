import 'package:flutter/material.dart';
import '../../models/catalogo_precio.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Registrar Catálogo de Precios (CRUD) - Jefe de Logística.
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
            children: lista
                .map((p) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.sell_outlined),
                        title: Text('${p.categoria}  ·  S/ ${p.precioDia.toStringAsFixed(2)}/día'),
                        subtitle: Text('${p.descripcion ?? ''}${p.vigente ? '' : '  (no vigente)'}'),
                        onTap: () => _abrirForm(p),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminar(p),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _abrirForm(CatalogoPrecio? p) async {
    final categoria = TextEditingController(text: p?.categoria ?? '');
    final descripcion = TextEditingController(text: p?.descripcion ?? '');
    final precio = TextEditingController(text: p?.precioDia.toString() ?? '');

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p == null ? 'Nuevo precio' : 'Editar precio'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(categoria, 'Categoría'),
            _campo(descripcion, 'Descripción'),
            _campo(precio, 'Precio por día', numero: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'categoria': categoria.text.trim(),
              'descripcion': descripcion.text.trim(),
              'precio_dia': double.tryParse(precio.text.trim()) ?? 0,
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
