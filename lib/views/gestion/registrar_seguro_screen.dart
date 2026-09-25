import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Registrar Seguro — interfaz completa. «include» Buscar Vehículo: al elegir el
/// vehículo se muestran sus datos y se completan los datos de la póliza.
class RegistrarSeguroScreen extends StatefulWidget {
  const RegistrarSeguroScreen({super.key});
  @override
  State<RegistrarSeguroScreen> createState() => _RegistrarSeguroScreenState();
}

class _RegistrarSeguroScreenState extends State<RegistrarSeguroScreen> {
  final _svc = GestionService();
  Vehiculo? _vehiculo;
  String _tipo = 'SOAT';
  final _poliza = TextEditingController();
  final _aseguradora = TextEditingController();
  final _emision = TextEditingController();
  final _vencimiento = TextEditingController();
  final _suma = TextEditingController();
  final _prima = TextEditingController();
  final _cobertura = TextEditingController();
  final _observaciones = TextEditingController();
  bool _guardando = false;

  static const _tipos = ['SOAT', 'TODO_RIESGO'];

  @override
  void dispose() {
    for (final c in [
      _poliza, _aseguradora, _emision, _vencimiento,
      _suma, _prima, _cobertura, _observaciones
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickFecha(TextEditingController c) async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year + 5),
    );
    if (d == null) return;
    c.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
    if (_vehiculo == null) {
      _snack('Selecciona un vehículo');
      return;
    }
    if (_poliza.text.trim().isEmpty) {
      _snack('Ingresa el N° de póliza');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.crearSeguro({
        'vehiculo_id': _vehiculo!.id,
        'tipo_seguro': _tipo,
        'num_poliza': _poliza.text.trim(),
        'aseguradora_entidad': _aseguradora.text.trim(),
        'fecha_emision': _emision.text.trim().isEmpty ? null : _emision.text.trim(),
        'fecha_vencimiento': _vencimiento.text.trim().isEmpty ? null : _vencimiento.text.trim(),
        'suma_asegurada': double.tryParse(_suma.text.trim()),
        'prima': double.tryParse(_prima.text.trim()),
        'cobertura': _cobertura.text.trim().isEmpty ? null : _cobertura.text.trim(),
        'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
      });
      if (!mounted) return;
      _snack('Póliza registrada');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehiculo;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar seguro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _vehiculo,
            label: 'Vehículo *',
            onChanged: (veh) => setState(() => _vehiculo = veh),
          ),
          const SizedBox(height: 12),
          if (v != null) _datosVehiculo(v),
          const SizedBox(height: 8),
          const Text('Datos de la póliza',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de seguro'),
              items: _tipos
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _tipo = val ?? _tipo),
            ),
          ),
          _campo(_poliza, 'N° de póliza *'),
          _campo(_aseguradora, 'Aseguradora'),
          Row(
            children: [
              Expanded(child: _campoFecha(_emision, 'Fecha emisión')),
              const SizedBox(width: 12),
              Expanded(child: _campoFecha(_vencimiento, 'Fecha vencimiento')),
            ],
          ),
          _campo(_suma, 'Suma asegurada (S/)', numero: true),
          _campo(_prima, 'Prima (S/)', numero: true),
          _campo(_cobertura, 'Cobertura (p. ej. daños, robo, terceros)'),
          _campo(_observaciones, 'Observaciones', lineas: 2),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando...' : 'Registrar seguro'),
          ),
        ],
      ),
    );
  }

  Widget _datosVehiculo(Vehiculo v) => Card(
        color: const Color(0xFFF3F6FA),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.descripcion,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('SKU: ${v.sku ?? '-'}  ·  Categoría: ${v.categoria ?? '-'}',
                  style: const TextStyle(color: Colors.black54)),
              Text('Año: ${v.anio ?? '-'}  ·  Color: ${v.color ?? '-'}  ·  ${v.estadoLegible}',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );

  Widget _campo(TextEditingController c, String label,
          {bool numero = false, int lineas = 1}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: numero ? TextInputType.number : TextInputType.text,
          maxLines: lineas,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _campoFecha(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          readOnly: true,
          onTap: () => _pickFecha(c),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
        ),
      );
}
