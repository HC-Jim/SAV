import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Vehículos (CRUD de datos) — «include» Buscar Vehículo.
/// Edita los datos del vehículo y permite crear uno nuevo. El SKU se genera
/// automáticamente y no es editable. El precio de alquiler y la garantía se
/// gestionan en la interfaz "Precio vehicular".
class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});
  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  final _svc = GestionService();
  static const _categorias = ['Economico', 'Sedan', 'SUV', 'Premium'];

  Vehiculo? _sel;
  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _anio = TextEditingController();
  final _color = TextEditingController();
  String _categoria = _categorias.first;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _anio, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _seleccionar(Vehiculo v) {
    setState(() {
      _sel = v;
      _placa.text = v.placa;
      _marca.text = v.marca ?? '';
      _modelo.text = v.modelo ?? '';
      _anio.text = v.anio?.toString() ?? '';
      _color.text = v.color ?? '';
      _categoria = (v.categoria != null && _categorias.contains(v.categoria))
          ? v.categoria!
          : _categorias.first;
    });
  }

  Future<void> _guardar() async {
    if (_sel == null) return;
    setState(() => _guardando = true);
    try {
      await _svc.actualizarVehiculo(_sel!.id, {
        'placa': _placa.text.trim(),
        'marca': _marca.text.trim(),
        'modelo': _modelo.text.trim(),
        'anio': int.tryParse(_anio.text.trim()),
        'color': _color.text.trim(),
        'categoria': _categoria,
      });
      if (!mounted) return;
      _snack('Datos guardados');
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _nuevoVehiculo() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _NuevoVehiculoScreen()),
    );
    if (creado == true) _snack('Vehículo creado');
  }

  @override
  Widget build(BuildContext context) {
    final v = _sel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos'),
        actions: [
          IconButton(
            tooltip: 'Nuevo vehículo',
            onPressed: _nuevoVehiculo,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _sel,
            label: 'Buscar vehículo',
            onChanged: _seleccionar,
          ),
          const SizedBox(height: 16),
          if (v == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Busca un vehículo para editar sus datos,\n'
                    'o crea uno nuevo con el botón +.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else ...[
            const Text('Datos del vehículo',
                style: TextStyle(fontWeight: FontWeight.bold)),
            _campo(TextEditingController(text: v.sku ?? '-'), 'SKU (no editable)',
                habilitado: false),
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
            const SizedBox(height: 8),
            Text('Precio de alquiler actual: S/ ${v.precioAlquiler.toStringAsFixed(2)}  ·  '
                'Garantía: S/ ${v.garantia.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const Text('El precio se gestiona en "Precio vehicular".',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar datos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _campo(TextEditingController c, String label,
          {bool numero = false, bool habilitado = true}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          enabled: habilitado,
          keyboardType: numero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

/// Formulario para crear un vehículo nuevo (con su precio y garantía iniciales).
class _NuevoVehiculoScreen extends StatefulWidget {
  const _NuevoVehiculoScreen();
  @override
  State<_NuevoVehiculoScreen> createState() => _NuevoVehiculoScreenState();
}

class _NuevoVehiculoScreenState extends State<_NuevoVehiculoScreen> {
  final _svc = GestionService();
  static const _categorias = ['Economico', 'Sedan', 'SUV', 'Premium'];

  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _anio = TextEditingController();
  final _color = TextEditingController();
  final _precio = TextEditingController();
  final _garantia = TextEditingController();
  final _costo = TextEditingController();
  String _categoria = _categorias.first;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _anio, _color, _precio, _garantia, _costo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _crear() async {
    if (_placa.text.trim().isEmpty) {
      _snack('La placa es obligatoria');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.crearVehiculo({
        'placa': _placa.text.trim(),
        'marca': _marca.text.trim(),
        'modelo': _modelo.text.trim(),
        'anio': int.tryParse(_anio.text.trim()),
        'color': _color.text.trim(),
        'categoria': _categoria,
        'precio_normal': double.tryParse(_precio.text.trim()) ?? 0,
        'garantia': double.tryParse(_garantia.text.trim()) ?? 0,
        'precio_costo': double.tryParse(_costo.text.trim()) ?? 0,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo vehículo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('El SKU se genera automáticamente al guardar. El precio '
              'inicial queda registrado en el historial de "Precio vehicular".',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          _campo(_placa, 'Placa *'),
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
          _campo(_precio, 'Precio de alquiler (S/ por ${Vehiculo.diasPorDefecto} días)',
              numero: true),
          _campo(_garantia, 'Garantía / depósito (S/)', numero: true),
          _campo(_costo, 'Precio costo (S/)', numero: true),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _crear,
            icon: const Icon(Icons.save),
            label: Text(_guardando ? 'Creando...' : 'Crear vehículo'),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {bool numero = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: numero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
