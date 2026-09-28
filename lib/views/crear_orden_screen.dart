import 'package:flutter/material.dart';
import '../models/tipo_mantenimiento.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
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
  final _kmCtrl = TextEditingController();
  final _fechaProgCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();

  static const _prioridades = ['BAJA', 'MEDIA', 'ALTA', 'URGENTE'];

  late Future<void> _carga;
  List<TipoMantenimiento> _tipos = [];
  Vehiculo? _vehiculo;
  Usuario? _mecanico;
  int? _tipoId;
  String _prioridad = 'MEDIA';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _vehiculo = widget.vehiculoPreseleccionado;
    _carga = _cargarDatos();
  }

  void _onVehiculo(Vehiculo? v) {
    setState(() {
      _vehiculo = v;
      // Prefill del km de ingreso con el kilometraje actual del vehículo.
      if (v?.kilometraje != null) _kmCtrl.text = '${v!.kilometraje}';
    });
  }

  TipoMantenimiento? get _tipoSel {
    for (final t in _tipos) {
      if (t.id == _tipoId) return t;
    }
    return null;
  }

  Future<void> _cargarDatos() async {
    // El vehículo y el mecánico se eligen con sus buscadores reutilizables
    // («include» Buscar Vehículo / Buscar Mecánico). Aquí solo se necesita el
    // catálogo de tipos de mantenimiento.
    _tipos = await _svc.tiposMantenimiento();
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _kmCtrl, _fechaProgCtrl, _costoCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFechaProg() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (d == null) return;
    _fechaProgCtrl.text =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
        prioridad: _prioridad,
        kmIngreso: int.tryParse(_kmCtrl.text.trim()),
        fechaProgramada:
            _fechaProgCtrl.text.trim().isEmpty ? null : _fechaProgCtrl.text.trim(),
        costoEstimado: double.tryParse(_costoCtrl.text.trim()),
      );
      if (!mounted) return;
      await _mostrarExito(orden.id, indicaciones);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Éxito → opción de imprimir la orden en PDF (funcionalidad de impresión).
  Future<void> _mostrarExito(int id, String? indicaciones) async {
    final imprimir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Orden creada con éxito'),
        content: Text('La orden de mantenimiento #$id se registró correctamente.\n\n'
            '¿Deseas imprimir el documento en PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Imprimir PDF'),
          ),
        ],
      ),
    );
    if (imprimir != true) return;

    TipoMantenimiento? tipo;
    for (final t in _tipos) {
      if (t.id == _tipoId) {
        tipo = t;
        break;
      }
    }
    await generarOrdenPdf(
      id: id,
      vehiculo: _vehiculo!,
      mecanico: _mecanico!.especialidad == null
          ? _mecanico!.nombre
          : '${_mecanico!.nombre} · ${_mecanico!.especialidad}',
      tipo: tipo?.nombre ?? '-',
      tipoDetalle: tipo?.frecuenciaTexto,
      indicaciones: indicaciones,
    );
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
                  onChanged: _onVehiculo,
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
                _infoTipo(_tipoSel),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _prioridad,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad *',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: _prioridades
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(_prioridadLegible(p))))
                      .toList(),
                  onChanged: (v) => setState(() => _prioridad = v ?? _prioridad),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _kmCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilometraje de ingreso (km)',
                    hintText: 'Odómetro al ingresar el vehículo',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fechaProgCtrl,
                  readOnly: true,
                  onTap: _pickFechaProg,
                  decoration: const InputDecoration(
                    labelText: 'Fecha programada',
                    hintText: 'Fecha estimada de atención',
                    prefixIcon: Icon(Icons.event),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Costo estimado (S/)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
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

  String _prioridadLegible(String p) {
    switch (p) {
      case 'BAJA':
        return 'Baja';
      case 'ALTA':
        return 'Alta';
      case 'URGENTE':
        return 'Urgente';
      default:
        return 'Media';
    }
  }

  Widget _infoTipo(TipoMantenimiento? t) => _tarjeta(
        icon: Icons.build_circle_outlined,
        titulo: t?.nombre ?? 'Datos del tipo de mantenimiento',
        activo: t != null,
        filas: [
          [
            'Categoría',
            t == null
                ? _vacio
                : (t.categoria == 'PROGRAMADO'
                    ? 'Programado'
                    : (t.categoria == 'NO_PROGRAMADO' ? 'No programado' : (t.categoria ?? _vacio)))
          ],
          ['Frecuencia', t?.frecuenciaTexto ?? _vacio],
          [
            'Duración estimada',
            t?.duracionEstimadaHoras != null ? '${t!.duracionEstimadaHoras} h' : _vacio
          ],
          ['Descripción', (t?.descripcion?.isNotEmpty ?? false) ? t!.descripcion! : _vacio],
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
