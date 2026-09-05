import 'package:flutter/material.dart';
import '../../models/repuesto.dart';
import '../../services/mantenimiento_service.dart';

/// Formulario único (Mecánico) que reúne, en una sola interfaz:
/// inspección → requerimiento de repuestos (con búsqueda del catálogo) →
/// mano de obra → generar presupuesto.
///
/// Reglas de negocio:
///  - Sin hallazgos: bloquea todo lo demás y cierra la orden.
///  - Postergada: solo registra la inspección (se retoma después).
///  - Con hallazgos: la mano de obra es obligatoria; el requerimiento de
///    repuestos solo si la inspección indica que se necesitan.
///
/// Devuelve el cuerpo listo para el backend o null si se cancela.
Future<Map<String, dynamic>?> mostrarInspeccionCompletaDialog(
    BuildContext context, MantenimientoService svc) {
  return Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _InspeccionCompletaScreen(svc: svc),
    ),
  );
}

class _InspeccionCompletaScreen extends StatefulWidget {
  final MantenimientoService svc;
  const _InspeccionCompletaScreen({required this.svc});

  @override
  State<_InspeccionCompletaScreen> createState() => _InspeccionCompletaScreenState();
}

class _InspeccionCompletaScreenState extends State<_InspeccionCompletaScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Inspección ---
  final _diagnostico = TextEditingController();
  final _kilometraje = TextEditingController();
  final _combustible = TextEditingController();
  final _observaciones = TextEditingController();
  final _justificacion = TextEditingController();
  String _resultado = 'CON_HALLAZGOS';
  bool _necesitaRepuestos = false;

  // --- Requerimiento de repuestos ---
  late Future<List<Repuesto>> _catalogo;
  List<Repuesto> _repuestos = [];
  final Map<int, int> _cantidades = {}; // repuesto_id -> cantidad
  final _buscar = TextEditingController();
  String _filtro = '';

  // --- Mano de obra ---
  final _costoMO = TextEditingController(text: '0');
  final _obsMO = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catalogo = widget.svc.catalogoRepuestos();
    _buscar.addListener(() => setState(() => _filtro = _buscar.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _diagnostico.dispose();
    _kilometraje.dispose();
    _combustible.dispose();
    _observaciones.dispose();
    _justificacion.dispose();
    _buscar.dispose();
    _costoMO.dispose();
    _obsMO.dispose();
    super.dispose();
  }

  double get _totalRepuestos {
    double t = 0;
    for (final r in _repuestos) {
      final c = _cantidades[r.id] ?? 0;
      t += c * r.costoUnitario;
    }
    return t;
  }

  double get _costoManoObra => double.tryParse(_costoMO.text.trim()) ?? 0;

  List<Repuesto> get _filtrados {
    if (_filtro.isEmpty) return _repuestos;
    return _repuestos.where((r) {
      final ref = (r.referencia ?? '').toLowerCase();
      return r.nombre.toLowerCase().contains(_filtro) || ref.contains(_filtro);
    }).toList();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;

    final inspeccion = <String, dynamic>{
      'diagnostico': _diagnostico.text.trim(),
      'resultado': _resultado,
      'necesita_repuestos': _resultado == 'CON_HALLAZGOS' && _necesitaRepuestos,
      'kilometraje_lectura': int.tryParse(_kilometraje.text.trim()),
      'nivel_combustible':
          _combustible.text.trim().isEmpty ? null : _combustible.text.trim(),
      'observaciones':
          _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
      'justificacion': _resultado == 'POSTERGADA' ? _justificacion.text.trim() : null,
    };

    // Sin hallazgos o postergada: solo la inspección (el backend cierra/posterga).
    if (_resultado != 'CON_HALLAZGOS') {
      Navigator.pop(context, {'inspeccion': inspeccion});
      return;
    }

    // Con hallazgos: la mano de obra es obligatoria.
    if (_costoManoObra <= 0) {
      _aviso('Ingresa el costo de mano de obra (mayor a 0).');
      return;
    }
    // Si se indicó que necesita repuestos, debe haber al menos uno.
    final items = _cantidades.entries
        .where((e) => e.value > 0)
        .map((e) => {'repuesto_id': e.key, 'cantidad': e.value})
        .toList();
    if (_necesitaRepuestos && items.isEmpty) {
      _aviso('Agrega al menos un repuesto o desactiva "¿Necesita repuestos?".');
      return;
    }

    Navigator.pop(context, {
      'inspeccion': inspeccion,
      'items': items,
      'mano_obra': {
        'costo': _costoManoObra,
        'observacion': _obsMO.text.trim().isEmpty ? null : _obsMO.text.trim(),
      },
    });
  }

  void _aviso(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final conHallazgos = _resultado == 'CON_HALLAZGOS';
    final postergada = _resultado == 'POSTERGADA';
    final total = _totalRepuestos + _costoManoObra;

    return Scaffold(
      appBar: AppBar(title: const Text('Inspección de mantenimiento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------------- INSPECCIÓN ----------------
            _titulo('1. Inspección', Icons.search),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _resultado,
              decoration: const InputDecoration(labelText: 'Resultado'),
              items: const [
                DropdownMenuItem(value: 'CON_HALLAZGOS', child: Text('Con hallazgos')),
                DropdownMenuItem(value: 'SIN_HALLAZGOS', child: Text('Sin hallazgos (cierra la orden)')),
                DropdownMenuItem(value: 'POSTERGADA', child: Text('Postergada')),
              ],
              onChanged: (v) => setState(() => _resultado = v ?? 'CON_HALLAZGOS'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnostico,
              decoration: const InputDecoration(labelText: 'Diagnóstico'),
              maxLines: 2,
              validator: (v) =>
                  (!postergada && (v == null || v.trim().isEmpty)) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            if (postergada)
              TextFormField(
                controller: _justificacion,
                decoration: const InputDecoration(labelText: 'Justificación de la postergación'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica el motivo' : null,
              )
            else ...[
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _kilometraje,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kilometraje'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _combustible,
                    decoration: const InputDecoration(labelText: 'Combustible'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observaciones,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 2,
              ),
            ],

            // "Sin hallazgos": se bloquea el resto del formulario.
            if (_resultado == 'SIN_HALLAZGOS')
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Card(
                  color: Color(0xFFF3F3F3),
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Sin hallazgos'),
                    subtitle: Text(
                        'No hay reparaciones que registrar. Al guardar, la orden se cierra.'),
                  ),
                ),
              ),

            if (conHallazgos) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Necesita repuestos?'),
                subtitle: const Text('Actívalo para registrar el requerimiento'),
                value: _necesitaRepuestos,
                onChanged: (v) => setState(() => _necesitaRepuestos = v),
              ),

              // ---------------- REQUERIMIENTO ----------------
              if (_necesitaRepuestos) ...[
                const Divider(height: 32),
                _titulo('2. Requerimiento de repuestos', Icons.add_shopping_cart),
                const SizedBox(height: 8),
                TextField(
                  controller: _buscar,
                  decoration: const InputDecoration(
                    labelText: 'Buscar repuesto',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                _listaRepuestos(),
              ],

              // ---------------- MANO DE OBRA ----------------
              const Divider(height: 32),
              _titulo('${_necesitaRepuestos ? '3' : '2'}. Mano de obra', Icons.build),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costoMO,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo de mano de obra (S/)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final c = double.tryParse((v ?? '').trim()) ?? 0;
                  return c <= 0 ? 'Ingresa un costo mayor a 0' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsMO,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observación de mano de obra (opcional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              // ---------------- RESUMEN ----------------
              const Divider(height: 32),
              _titulo('Resumen del presupuesto', Icons.request_quote_outlined),
              const SizedBox(height: 8),
              _filaTotal('Repuestos', _totalRepuestos),
              _filaTotal('Mano de obra', _costoManoObra),
              _filaTotal('Total', total, negrita: true),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _enviar,
              icon: Icon(conHallazgos
                  ? Icons.request_quote
                  : (postergada ? Icons.save : Icons.lock_outline)),
              label: Text(conHallazgos
                  ? 'Generar presupuesto'
                  : (postergada ? 'Guardar (postergar)' : 'Cerrar orden (sin hallazgos)')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _listaRepuestos() {
    return FutureBuilder<List<Repuesto>>(
      future: _catalogo,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) return Text('${snap.error}');
        _repuestos = snap.data ?? [];
        final lista = _filtrados;
        if (lista.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin repuestos que coincidan.'),
          );
        }
        return Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final r = lista[i];
                final cant = _cantidades[r.id] ?? 0;
                return ListTile(
                  dense: true,
                  title: Text(r.nombre),
                  subtitle: Text('S/ ${r.costoUnitario.toStringAsFixed(2)}  ·  stock ${r.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: cant > 0
                            ? () => setState(() => _cantidades[r.id] = cant - 1)
                            : null,
                      ),
                      Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _cantidades[r.id] = cant + 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _titulo(String texto, IconData icono) => Row(
        children: [
          Icon(icono, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );

  Widget _filaTotal(String k, double v, {bool negrita = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                    fontSize: negrita ? 16 : 14)),
            Text('S/ ${v.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                    fontSize: negrita ? 16 : 14)),
          ],
        ),
      );
}
