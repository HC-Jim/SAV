import 'package:flutter/material.dart';
import '../models/tipo_mantenimiento.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../models/orden_mantenimiento.dart';
import '../services/api_client.dart';
import '../services/mantenimiento_service.dart';
import '../services/pdf_generator.dart';
import '../widgets/selector_mecanico.dart';
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
  final _descCtrl = TextEditingController();

  late Future<void> _carga;
  List<TipoMantenimiento> _tipos = [];
  Vehiculo? _vehiculo;
  Usuario? _mecanico;
  int? _tipoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _vehiculo = widget.vehiculoPreseleccionado;
    _carga = _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // El vehículo y el mecánico se eligen con sus buscadores reutilizables
    // («include» Buscar Vehículo / Buscar Mecánico). Aquí solo se necesita el
    // catálogo de tipos de mantenimiento.
    _tipos = await _svc.tiposMantenimiento();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final formOk = _formKey.currentState!.validate();
    if (_vehiculo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un vehículo')));
      return;
    }
    if (_mecanico == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un mecánico')));
      return;
    }
    if (!formOk) return;
    setState(() => _guardando = true);
    try {
      final indicaciones =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final orden = await _svc.crearOrden(
        vehiculoId: _vehiculo!.id,
        mecanicoId: _mecanico!.id,
        tipoMantenimientoId: _tipoId!,
        indicaciones: indicaciones,
      );
      if (!mounted) return;
      await _flujoExito(orden, indicaciones);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// «extends» Imprimir documento: éxito → ¿imprimir la orden en PDF?
  Future<void> _flujoExito(OrdenMantenimiento orden, String? indicaciones) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Orden creada con éxito'),
        content: Text('La orden de mantenimiento #${orden.id} se registró correctamente.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    final imprimir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.print_outlined, size: 36),
        title: const Text('Imprimir documento'),
        content: const Text('¿Desea imprimir el documento de la orden de mantenimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );

    if (imprimir == true) {
      TipoMantenimiento? tipo;
      for (final t in _tipos) {
        if (t.id == _tipoId) {
          tipo = t;
          break;
        }
      }
      await generarOrdenPdf(
        id: orden.id,
        vehiculo: _vehiculo!,
        mecanico: _mecanico!.especialidad == null
            ? _mecanico!.nombre
            : '${_mecanico!.nombre} · ${_mecanico!.especialidad}',
        tipo: tipo?.nombre ?? '-',
        tipoDetalle: tipo?.frecuenciaTexto,
        indicaciones: indicaciones,
      );
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
                _infoVehiculo(_vehiculo),
                const SizedBox(height: 16),
                SelectorMecanico(
                  value: _mecanico,
                  label: 'Mecánico *',
                  onChanged: (m) => setState(() => _mecanico = m),
                ),
                _infoMecanico(_mecanico),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _tipoId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mantenimiento *',
                    prefixIcon: Icon(Icons.build),
                  ),
                  selectedItemBuilder: (_) => _tipos
                      .map((t) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t.nombre,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  items: _tipos
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.nombre,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  '${t.categoria == 'PROGRAMADO' ? 'Programado' : 'No programado'} · ${t.frecuenciaTexto}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoId = v),
                  validator: (v) => v == null ? 'Selecciona un tipo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Indicaciones',
                    hintText: 'Detalles o indicaciones para el mecánico...',
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

  // ---------- tarjetas de datos ----------

  static const String _vacio = '—';

  Widget _infoVehiculo(Vehiculo? v) => _tarjeta(
        icon: Icons.directions_car,
        titulo: v?.descripcion ?? 'Datos del vehículo',
        activo: v != null,
        filas: [
          ['Placa', v?.placa ?? _vacio],
          ['Categoría', v?.categoria ?? _vacio],
          ['Año', v?.anio?.toString() ?? _vacio],
          ['Color', v?.color ?? _vacio],
          ['Kilometraje', v?.kilometraje != null ? '${v!.kilometraje} km' : _vacio],
          ['Estado', v?.estadoLegible ?? _vacio],
        ],
      );

  Widget _infoMecanico(Usuario? m) => _tarjeta(
        icon: Icons.engineering,
        titulo: m?.nombre ?? 'Datos del mecánico',
        activo: m != null,
        filas: [
          ['Especialidad', m?.especialidad ?? _vacio],
          ['Jornada', m != null ? m.jornadaLegible : _vacio],
          ['Teléfono', m?.telefono ?? _vacio],
          [
            'Disponibilidad',
            m?.disponible == null
                ? _vacio
                : (m!.disponible! ? 'Disponible' : 'No disponible')
          ],
          ['Órdenes activas', m?.ordenesActivas?.toString() ?? _vacio],
        ],
      );

  Widget _tarjeta({
    required IconData icon,
    required String titulo,
    required List<List<String>> filas,
    bool activo = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: activo ? Colors.black87 : Colors.black38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(titulo,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: activo ? Colors.black87 : Colors.black45)),
                    ),
                    if (!activo)
                      const Text('Sin seleccionar',
                          style: TextStyle(fontSize: 12, color: Colors.black38)),
                  ],
                ),
                const Divider(height: 16),
                ...filas.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(f[0],
                                style:
                                    const TextStyle(color: Colors.black54)),
                          ),
                          Expanded(child: Text(f[1])),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      );
}
