import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Registrar Seguro — interfaz completa. «include» Buscar Vehículo: la tarjeta
/// del vehículo es visible desde el inicio y se llena al elegirlo; luego se
/// completan los datos de la póliza, montos y coberturas.
class RegistrarSeguroScreen extends StatefulWidget {
  const RegistrarSeguroScreen({super.key});
  @override
  State<RegistrarSeguroScreen> createState() => _RegistrarSeguroScreenState();
}

class _RegistrarSeguroScreenState extends State<RegistrarSeguroScreen> {
  final _svc = GestionService();
  Vehiculo? _vehiculo;

  String _tipo = 'SOAT';
  String _moneda = 'PEN';
  String _frecuencia = 'ANUAL';
  final _poliza = TextEditingController();
  final _aseguradora = TextEditingController();
  final _contacto = TextEditingController();
  final _emision = TextEditingController();
  final _vencimiento = TextEditingController();
  final _suma = TextEditingController();
  final _prima = TextEditingController();
  final _deducible = TextEditingController();
  final _observaciones = TextEditingController();

  // Coberturas (checkboxes) → se guardan unidas en el campo cobertura.
  final Map<String, bool> _coberturas = {
    'Daños propios': false,
    'Robo': false,
    'Responsabilidad civil (terceros)': false,
    'Asistencia en carretera': false,
  };

  bool _guardando = false;

  static const _tipos = ['SOAT', 'TODO_RIESGO'];
  static const _monedas = ['PEN', 'USD'];
  static const _frecuencias = ['MENSUAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL'];
  static const String _vacio = '—';

  @override
  void dispose() {
    for (final c in [
      _poliza, _aseguradora, _contacto, _emision, _vencimiento,
      _suma, _prima, _deducible, _observaciones
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
    final coberturas = _coberturas.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');
    setState(() => _guardando = true);
    try {
      await _svc.crearSeguro({
        'vehiculo_id': _vehiculo!.id,
        'tipo_seguro': _tipo,
        'num_poliza': _poliza.text.trim(),
        'aseguradora_entidad': _aseguradora.text.trim(),
        'contacto_aseguradora': _contacto.text.trim().isEmpty ? null : _contacto.text.trim(),
        'moneda': _moneda,
        'fecha_emision': _emision.text.trim().isEmpty ? null : _emision.text.trim(),
        'fecha_vencimiento': _vencimiento.text.trim().isEmpty ? null : _vencimiento.text.trim(),
        'suma_asegurada': double.tryParse(_suma.text.trim()),
        'prima': double.tryParse(_prima.text.trim()),
        'deducible': double.tryParse(_deducible.text.trim()),
        'frecuencia_pago': _frecuencia,
        'cobertura': coberturas.isEmpty ? null : coberturas,
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
          _datosVehiculo(_vehiculo),
          const SizedBox(height: 12),

          _tituloSeccion('Datos de la póliza'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de seguro'),
              items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _tipo = val ?? _tipo),
            ),
          ),
          _campo(_poliza, 'N° de póliza *'),
          _campo(_aseguradora, 'Aseguradora'),
          _campo(_contacto, 'Contacto de la aseguradora (teléfono / correo)'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              initialValue: _moneda,
              decoration: const InputDecoration(labelText: 'Moneda'),
              items: _monedas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _moneda = val ?? _moneda),
            ),
          ),
          Row(
            children: [
              Expanded(child: _campoFecha(_emision, 'Fecha emisión')),
              const SizedBox(width: 12),
              Expanded(child: _campoFecha(_vencimiento, 'Fecha vencimiento')),
            ],
          ),

          const SizedBox(height: 8),
          _tituloSeccion('Montos'),
          _campo(_suma, 'Suma asegurada (S/)', numero: true),
          _campo(_prima, 'Prima (S/)', numero: true),
          _campo(_deducible, 'Deducible (S/)', numero: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              initialValue: _frecuencia,
              decoration: const InputDecoration(labelText: 'Frecuencia de pago'),
              items: _frecuencias
                  .map((f) => DropdownMenuItem(value: f, child: Text(_frecLegible(f))))
                  .toList(),
              onChanged: (val) => setState(() => _frecuencia = val ?? _frecuencia),
            ),
          ),

          const SizedBox(height: 8),
          _tituloSeccion('Coberturas'),
          ..._coberturas.keys.map((k) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(k),
                value: _coberturas[k],
                onChanged: (v) => setState(() => _coberturas[k] = v ?? false),
              )),

          const SizedBox(height: 8),
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

  String _frecLegible(String f) {
    switch (f) {
      case 'MENSUAL':
        return 'Mensual';
      case 'TRIMESTRAL':
        return 'Trimestral';
      case 'SEMESTRAL':
        return 'Semestral';
      default:
        return 'Anual';
    }
  }

  Widget _tituloSeccion(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _datosVehiculo(Vehiculo? v) => Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.directions_car,
                    size: 20, color: v == null ? Colors.black38 : Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(v?.descripcion ?? 'Datos del vehículo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: v == null ? Colors.black45 : Colors.black87)),
                ),
                if (v == null)
                  const Text('Sin seleccionar',
                      style: TextStyle(fontSize: 12, color: Colors.black38)),
              ]),
              const Divider(height: 16),
              _fila('SKU', v?.sku ?? _vacio),
              _fila('Categoría', v?.categoria ?? _vacio),
              _fila('Año', v?.anio?.toString() ?? _vacio),
              _fila('Color', v?.color ?? _vacio),
              _fila('Estado', v?.estadoLegible ?? _vacio),
            ],
          ),
        ),
      );

  Widget _fila(String k, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(val)),
        ]),
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
