import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Mantener Vehículo (CRUD) - Administrador. Solo datos del vehículo (el precio
/// se gestiona en Catálogo de Precios, por categoría).
class VehiculosAdminScreen extends StatefulWidget {
  const VehiculosAdminScreen({super.key});
  @override
  State<VehiculosAdminScreen> createState() => _VehiculosAdminScreenState();
}

class _VehiculosAdminScreenState extends State<VehiculosAdminScreen> {
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

  Future<void> _guardar(Vehiculo? v, Map<String, dynamic> datos) async {
    try {
      if (v == null) {
        await _svc.crearVehiculo(datos);
      } else {
        await _svc.actualizarVehiculo(v.id, datos);
      }
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  Future<void> _eliminar(Vehiculo v) async {
    try {
      await _svc.eliminarVehiculo(v.id);
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehículos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(null),
        child: const Icon(Icons.add),
      ),
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
            children: lista
                .map((v) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text('${v.marca ?? ''} ${v.modelo ?? ''}'.trim()),
                        subtitle: Text('SKU: ${v.sku ?? '-'}  ·  ${v.placa}  ·  '
                            '${v.categoria ?? 'sin categoría'}  ·  ${v.estado ?? ''}'),
                        onTap: () => _abrirForm(v),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmarEliminar(v),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(Vehiculo v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Eliminar ${v.placa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) _eliminar(v);
  }

  Future<void> _abrirForm(Vehiculo? v) async {
    // Categorías disponibles (del catálogo de precios).
    List<String> categorias = [];
    try {
      final precios = await _svc.listarPrecios();
      categorias = precios.map((p) => p.categoria).toList();
    } on ApiException catch (_) {
      categorias = [];
    }
    if (!mounted) return;

    final sku = TextEditingController(text: v?.sku ?? '');
    final placa = TextEditingController(text: v?.placa ?? '');
    final marca = TextEditingController(text: v?.marca ?? '');
    final modelo = TextEditingController(text: v?.modelo ?? '');
    final anio = TextEditingController(text: v?.anio?.toString() ?? '');
    final color = TextEditingController(text: v?.color ?? '');
    String? categoria = (v?.categoria != null && categorias.contains(v!.categoria))
        ? v.categoria
        : (categorias.isNotEmpty ? categorias.first : null);

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(v == null ? 'Nuevo vehículo' : 'Editar vehículo'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _campo(sku, 'SKU'),
              _campo(placa, 'Placa'),
              _campo(marca, 'Marca'),
              _campo(modelo, 'Modelo'),
              _campo(anio, 'Año', numero: true),
              _campo(color, 'Color'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setLocal(() => categoria = val),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'sku': sku.text.trim(),
                'placa': placa.text.trim(),
                'marca': marca.text.trim(),
                'modelo': modelo.text.trim(),
                'anio': int.tryParse(anio.text.trim()),
                'color': color.text.trim(),
                'categoria': categoria,
              }),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (datos != null) _guardar(v, datos);
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
