import 'package:flutter/material.dart';
import '../../models/repuesto.dart';
import '../../services/mantenimiento_service.dart';

/// Diálogo para generar el presupuesto: mano de obra + detalle de repuestos.
/// Devuelve { costo_mano_obra, detalle:[{repuesto_id, cantidad}] } o null.
Future<Map<String, dynamic>?> mostrarPresupuestoDialog(
    BuildContext context, MantenimientoService svc) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _PresupuestoDialog(svc: svc),
  );
}

class _PresupuestoDialog extends StatefulWidget {
  final MantenimientoService svc;
  const _PresupuestoDialog({required this.svc});
  @override
  State<_PresupuestoDialog> createState() => _PresupuestoDialogState();
}

class _PresupuestoDialogState extends State<_PresupuestoDialog> {
  late Future<List<Repuesto>> _futuro;
  final _manoObra = TextEditingController(text: '0');
  final Map<int, int> _cantidades = {};
  List<Repuesto> _repuestos = [];

  @override
  void initState() {
    super.initState();
    _futuro = widget.svc.catalogoRepuestos().then((r) => _repuestos = r);
  }

  @override
  void dispose() {
    _manoObra.dispose();
    super.dispose();
  }

  double get _totalRepuestos {
    double t = 0;
    for (final r in _repuestos) {
      t += (r.costoUnitario) * (_cantidades[r.id] ?? 0);
    }
    return t;
  }

  void _guardar() {
    final detalle = _cantidades.entries
        .where((e) => e.value > 0)
        .map((e) => {'repuesto_id': e.key, 'cantidad': e.value})
        .toList();
    Navigator.pop(context, {
      'costo_mano_obra': double.tryParse(_manoObra.text.trim()) ?? 0,
      'detalle': detalle,
    });
  }

  @override
  Widget build(BuildContext context) {
    final manoObra = double.tryParse(_manoObra.text.trim()) ?? 0;
    return AlertDialog(
      title: const Text('Generar presupuesto'),
      content: SizedBox(
        width: 440,
        height: 440,
        child: FutureBuilder<List<Repuesto>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            return Column(
              children: [
                TextField(
                  controller: _manoObra,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Costo de mano de obra (S/)', prefixIcon: Icon(Icons.build)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Repuestos:', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  child: ListView.builder(
                    itemCount: _repuestos.length,
                    itemBuilder: (context, i) {
                      final r = _repuestos[i];
                      final cant = _cantidades[r.id] ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(r.nombre),
                        subtitle: Text('S/ ${r.costoUnitario.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: cant > 0
                                  ? () => setState(() => _cantidades[r.id] = cant - 1)
                                  : null,
                            ),
                            Text('$cant'),
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
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: S/ ${(_totalRepuestos + manoObra).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Generar')),
      ],
    );
  }
}
