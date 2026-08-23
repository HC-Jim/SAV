import 'package:flutter/material.dart';
import '../models/repuesto.dart';
import '../services/mantenimiento_service.dart';

class RepuestosScreen extends StatefulWidget {
  const RepuestosScreen({super.key});
  @override
  State<RepuestosScreen> createState() => _RepuestosScreenState();
}

class _RepuestosScreenState extends State<RepuestosScreen> {
  final _svc = MantenimientoService();
  late Future<List<Repuesto>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _svc.catalogoRepuestos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de repuestos')),
      body: FutureBuilder<List<Repuesto>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final repuestos = snap.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: repuestos.length,
            itemBuilder: (context, i) {
              final r = repuestos[i];
              final sinStock = r.stock <= 0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: Text(r.nombre),
                  subtitle: Text('Ref: ${r.referencia ?? '-'}  ·  '
                      'S/ ${r.costoUnitario.toStringAsFixed(2)}'),
                  trailing: Chip(
                    label: Text('Stock: ${r.stock}'),
                    backgroundColor: sinStock
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
