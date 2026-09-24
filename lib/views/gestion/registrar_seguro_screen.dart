import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Registrar Seguro — interfaz completa. «include» Buscar Vehículo para elegir
/// el vehículo y registrar su póliza.
class RegistrarSeguroScreen extends StatefulWidget {
  const RegistrarSeguroScreen({super.key});
  @override
  State<RegistrarSeguroScreen> createState() => _RegistrarSeguroScreenState();
}

class _RegistrarSeguroScreenState extends State<RegistrarSeguroScreen> {
  final _svc = GestionService();
  Vehiculo? _vehiculo;
  final _tipo = TextEditingController(text: 'SOAT');
  final _poliza = TextEditingController();
  final _aseguradora = TextEditingController();
  final _emision = TextEditingController();
  final _vencimiento = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_tipo, _poliza, _aseguradora, _emision, _vencimiento]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _guardar() async {
    if (_vehiculo == null) {
      _snack('Selecciona un vehículo');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.crearSeguro({
        'vehiculo_id': _vehiculo!.id,
        'tipo_seguro': _tipo.text.trim(),
        'num_poliza': _poliza.text.trim(),
        'aseguradora_entidad': _aseguradora.text.trim(),
        'fecha_emision': _emision.text.trim().isEmpty ? null : _emision.text.trim(),
        'fecha_vencimiento': _vencimiento.text.trim().isEmpty ? null : _vencimiento.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar seguro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _vehiculo,
            label: 'Vehículo *',
            onChanged: (v) => setState(() => _vehiculo = v),
          ),
          _campo(_tipo, 'Tipo (SOAT / TODO_RIESGO)'),
          _campo(_poliza, 'N° de póliza'),
          _campo(_aseguradora, 'Aseguradora'),
          _campo(_emision, 'Fecha emisión (YYYY-MM-DD)'),
          _campo(_vencimiento, 'Fecha vencimiento (YYYY-MM-DD)'),
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

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: c, decoration: InputDecoration(labelText: label)),
      );
}
