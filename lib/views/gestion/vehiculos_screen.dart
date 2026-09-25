import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Vehículos (CRUD) — «include» Buscar Vehículo.
/// Interfaz única para editar los datos del vehículo y/o su precio de alquiler
/// y garantía, ver la variación de precios (último, promedio) y crear un
/// vehículo nuevo. El SKU se genera automáticamente y no es editable.
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
  final _precio = TextEditingController();
  final _garantia = TextEditingController();
  String _categoria = _categorias.first;

  Map<String, dynamic>? _stats;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _anio, _color, _precio, _garantia]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _seleccionar(Vehiculo v) async {
    setState(() {
      _sel = v;
      _placa.text = v.placa;
      _marca.text = v.marca ?? '';
      _modelo.text = v.modelo ?? '';
      _anio.text = v.anio?.toString() ?? '';
      _color.text = v.color ?? '';
      _precio.text = v.precioAlquiler.toStringAsFixed(2);
      _garantia.text = v.garantia.toStringAsFixed(2);
      _categoria = (v.categoria != null && _categorias.contains(v.categoria))
          ? v.categoria!
          : _categorias.first;
      _stats = null;
    });
    await _cargarStats(v.id);
  }

  Future<void> _cargarStats(int id) async {
    try {
      final s = await _svc.historialPrecios(id);
      if (mounted) setState(() => _stats = s);
    } on ApiException catch (_) {
      // Silencioso: las estadísticas son informativas.
    }
  }

  Future<void> _guardar() async {
    if (_sel == null) return;
    setState(() => _guardando = true);
    try {
      // 1) Datos del vehículo
      await _svc.actualizarVehiculo(_sel!.id, {
        'placa': _placa.text.trim(),
        'marca': _marca.text.trim(),
        'modelo': _modelo.text.trim(),
        'anio': int.tryParse(_anio.text.trim()),
        'color': _color.text.trim(),
        'categoria': _categoria,
      });
      // 2) Precio/garantía (solo si cambiaron, para no ensuciar el historial)
      final precio = double.tryParse(_precio.text.trim()) ?? 0;
      final garantia = double.tryParse(_garantia.text.trim()) ?? 0;
      final cambioPrecio =
          precio != _sel!.precioAlquiler || garantia != _sel!.garantia;
      if (cambioPrecio) {
        await _svc.actualizarPrecioVehiculo(
            _sel!.id, {'precio_normal': precio, 'garantia': garantia});
      }
      if (!mounted) return;
      _snack('Cambios guardados');
      // Refresca el vehículo en memoria y las estadísticas.
      setState(() => _sel = Vehiculo(
            id: _sel!.id,
            sku: _sel!.sku,
            placa: _placa.text.trim(),
            marca: _marca.text.trim(),
            modelo: _modelo.text.trim(),
            anio: int.tryParse(_anio.text.trim()),
            color: _color.text.trim(),
            categoria: _categoria,
            precioAlquiler: precio,
            garantia: garantia,
            kilometraje: _sel!.kilometraje,
            fechaProximoMantenimiento: _sel!.fechaProximoMantenimiento,
            estado: _sel!.estado,
          ));
      if (cambioPrecio) await _cargarStats(_sel!.id);
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
                child: Text('Busca un vehículo para editar sus datos y precios,\n'
                    'o crea uno nuevo con el botón +.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else ...[
            if (_stats != null) _cardStats(v),
            const SizedBox(height: 12),
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
            const Text('Precios',
                style: TextStyle(fontWeight: FontWeight.bold)),
            _campo(_precio, 'Precio de alquiler (S/ por ${Vehiculo.diasPorDefecto} días)',
                numero: true),
            _campo(_garantia, 'Garantía / depósito (S/)', numero: true),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardStats(Vehiculo v) {
    final s = _stats!;
    final ultimo = (s['ultimo'] as num?)?.toDouble() ?? 0;
    final promedio = (s['promedio'] as num?)?.toDouble() ?? 0;
    final variacion = (s['variacion'] as num?)?.toDouble() ?? 0;
    final variacionPct = (s['variacion_pct'] as num?)?.toDouble() ?? 0;
    final cambios = (s['cambios'] as num?)?.toInt() ?? 0;
    final subeBaja = variacion == 0
        ? 'sin variación'
        : (variacion > 0
            ? '▲ S/ ${variacion.toStringAsFixed(2)} (${variacionPct.toStringAsFixed(1)}%)'
            : '▼ S/ ${variacion.abs().toStringAsFixed(2)} (${variacionPct.toStringAsFixed(1)}%)');
    return Card(
      color: const Color(0xFFF3F6FA),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.descripcion,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Categoría: ${v.categoria ?? '-'}  ·  ${v.estadoLegible}',
                style: const TextStyle(color: Colors.black54)),
            const Divider(),
            _filaStat('Último precio', 'S/ ${ultimo.toStringAsFixed(2)}'),
            _filaStat('Precio promedio', 'S/ ${promedio.toStringAsFixed(2)}'),
            _filaStat('Variación total', subeBaja),
            _filaStat('N° de cambios de precio', '$cambios'),
          ],
        ),
      ),
    );
  }

  Widget _filaStat(String k, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.black87)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

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

/// Formulario para crear un vehículo nuevo (con su precio y garantía).
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
  String _categoria = _categorias.first;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _anio, _color, _precio, _garantia]) {
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
          const Text('El SKU se genera automáticamente al guardar.',
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
