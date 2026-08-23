import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../services/api_client.dart';
import '../services/mantenimiento_service.dart';

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
  List<Vehiculo> _vehiculos = [];
  List<Usuario> _mecanicos = [];
  int? _vehiculoId;
  int? _mecanicoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _vehiculoId = widget.vehiculoPreseleccionado?.id;
    _carga = _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final res = await Future.wait([
      _svc.vehiculosPorMantener(),
      _svc.listarMecanicos(),
    ]);
    _vehiculos = res[0] as List<Vehiculo>;
    _mecanicos = res[1] as List<Usuario>;
    // Asegura que el vehículo preseleccionado esté en la lista.
    if (widget.vehiculoPreseleccionado != null &&
        !_vehiculos.any((v) => v.id == _vehiculoId)) {
      _vehiculos = [widget.vehiculoPreseleccionado!, ..._vehiculos];
    }
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _vehiculoId == null) {
      if (_vehiculoId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Selecciona un vehículo')));
      }
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.crearOrden(
        vehiculoId: _vehiculoId!,
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
                DropdownButtonFormField<int>(
                  initialValue: _vehiculoId,
                  decoration: const InputDecoration(
                    labelText: 'Vehículo *',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: _vehiculos
                      .map((v) => DropdownMenuItem(
                          value: v.id, child: Text(v.descripcion)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehiculoId = v),
                  validator: (v) => v == null ? 'Selecciona un vehículo' : null,
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
