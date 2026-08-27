import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Editar / eliminar (o crear) un vehículo. Se abre desde Gestión de vehículos
/// (Administrador) al tocar un vehículo de la lista.
class EditarVehiculoScreen extends StatefulWidget {
  /// `null` = crear un vehículo nuevo.
  final Vehiculo? vehiculo;
  const EditarVehiculoScreen({super.key, this.vehiculo});

  @override
  State<EditarVehiculoScreen> createState() => _EditarVehiculoScreenState();
}

class _EditarVehiculoScreenState extends State<EditarVehiculoScreen> {
  final _svc = GestionService();
  static const _categorias = ['Economico', 'Sedan', 'SUV', 'Premium'];

  late final TextEditingController _sku;
  late final TextEditingController _placa;
  late final TextEditingController _marca;
  late final TextEditingController _modelo;
  late final TextEditingController _anio;
  late final TextEditingController _color;
  late String _categoria;
  bool _guardando = false;

  bool get _esNuevo => widget.vehiculo == null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    _sku = TextEditingController(text: v?.sku ?? '');
    _placa = TextEditingController(text: v?.placa ?? '');
    _marca = TextEditingController(text: v?.marca ?? '');
    _modelo = TextEditingController(text: v?.modelo ?? '');
    _anio = TextEditingController(text: v?.anio?.toString() ?? '');
    _color = TextEditingController(text: v?.color ?? '');
    _categoria = (v?.categoria != null && _categorias.contains(v!.categoria))
        ? v.categoria!
        : _categorias.first;
  }

  @override
  void dispose() {
    for (final c in [_sku, _placa, _marca, _modelo, _anio, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final datos = {
      'sku': _sku.text.trim(),
      'placa': _placa.text.trim(),
      'marca': _marca.text.trim(),
      'modelo': _modelo.text.trim(),
      'anio': int.tryParse(_anio.text.trim()),
      'color': _color.text.trim(),
      'categoria': _categoria,
    };
    try {
      if (_esNuevo) {
        await _svc.crearVehiculo(datos);
      } else {
        await _svc.actualizarVehiculo(widget.vehiculo!.id, datos);
      }
      if (!mounted) return;
      _snack(_esNuevo ? 'Vehículo creado' : 'Vehículo actualizado');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Eliminar ${widget.vehiculo!.placa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.eliminarVehiculo(widget.vehiculo!.id);
      if (!mounted) return;
      _snack('Vehículo eliminado');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Nuevo vehículo' : 'Editar vehículo'),
        actions: [
          if (!_esNuevo)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _campo(_sku, 'SKU'),
          _campo(_placa, 'Placa'),
          _campo(_marca, 'Marca'),
          _campo(_modelo, 'Modelo'),
          _campo(_anio, 'Año', numero: true),
          _campo(_color, 'Color'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _categoria = val ?? _categoria),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
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
