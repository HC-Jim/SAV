import 'package:flutter/material.dart';
import '../../models/repuesto.dart';
import '../../services/mantenimiento_service.dart';

/// Diálogo para armar un requerimiento de repuestos desde el catálogo.
/// Devuelve la lista de items [{repuesto_id, cantidad}] o null.
Future<List<Map<String, dynamic>>?> mostrarRequerimientoDialog(
    BuildContext context, MantenimientoService svc) {
  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (_) => _RequerimientoDialog(svc: svc),
  );
}

class _RequerimientoDialog extends StatefulWidget {
  final MantenimientoService svc;
  const _RequerimientoDialog({required this.svc});
  @override
  State<_RequerimientoDialog> createState() => _RequerimientoDialogState();
}

class _RequerimientoDialogState extends State<_RequerimientoDialog> {
  late Future<List<Repuesto>> _futuro;
  final Map<int, int> _cantidades = {}; // repuesto_id -> cantidad

  @override
  void initState() {
    super.initState();
    _futuro = widget.svc.catalogoRepuestos();
  }

  void _guardar() {
    final items = _cantidades.entries
        .where((e) => e.value > 0)
        .map((e) => {'repuesto_id': e.key, 'cantidad': e.value})
        .toList();
    Navigator.pop(context, items);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Requerimiento de repuestos'),
      content: SizedBox(
        width: 420,
        height: 380,
        child: FutureBuilder<List<Repuesto>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            final repuestos = snap.data ?? [];
            return ListView.builder(
              itemCount: repuestos.length,
              itemBuilder: (context, i) {
                final r = repuestos[i];
                final cant = _cantidades[r.id] ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
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
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Solicitar')),
      ],
    );
  }
}
