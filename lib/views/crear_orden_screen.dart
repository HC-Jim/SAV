import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../services/api_client.dart';
import '../services/mantenimiento_service.dart';
import '../widgets/selector_vehiculo.dart';

/// Formulario del Jefe de Logística para crear una Orden de Mantenimiento.
class CrearOrdenScreen extends StatefulWidget {
  final Vehiculo? vehiculoPreseleccionado;
  const CrearOrdenScreen({super.key, this.vehiculoPreseleccionado});

  @override
  State<CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<CrearOrdenScreen> {
  final _svc = MantenimientoService();
  final _formKey = GlobalKey<FormState>();
  final _tipoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late Future<void> _carga;
  List<Usuario> _mecanicos = [];
  Vehiculo? _vehiculo;
  int? _mecanicoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _vehiculo = widget.vehiculoPreseleccionado;
    _carga = _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // El vehículo se elige con el SelectorVehiculo («include» Buscar Vehículo);
    // aquí solo hace falta la lista de mecánicos.
    _mecanicos = await _svc.listarMecanicos();
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _vehiculo == null) {
      if (_vehiculo == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Selecciona un vehículo')));
      }
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.crearOrden(
        vehiculoId: _vehiculo!.id,
        mecanicoId: _mecanicoId,
        tipoServicio: _tipoCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden creada correctamente')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear orden de mantenimiento')),
      body: FutureBuilder(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SelectorVehiculo(
                  value: _vehiculo,
                  soloDisponibles: true,
                  label: 'Vehículo *',
                  onChanged: (v) => setState(() => _vehiculo = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _mecanicoId,
                  decoration: const InputDecoration(
                    labelText: 'Mecánico asignado (opcional)',
                    prefixIcon: Icon(Icons.engineering),
                  ),
                  items: _mecanicos
                      .map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _mecanicoId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de servicio *',
                    hintText: 'Ej. Preventivo 50,000 km',
                    prefixIcon: Icon(Icons.build),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save),
                  label: Text(_guardando ? 'Guardando...' : 'Crear orden'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
