import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repuesto.dart';
import '../services/mantenimiento_service.dart';
import '../state/auth_controller.dart';
import 'comprar_repuesto_screen.dart';

/// Catálogo de repuestos (Mecánico y Jefe). El Jefe puede tocar un repuesto
/// para comprar más stock.
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
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.catalogoRepuestos());

  Future<void> _comprar(Repuesto r) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ComprarRepuestoScreen(repuesto: r)),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final esJefe = context.watch<AuthController>().usuario?.esJefe ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de repuestos'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(sinStock ? 'Sin stock' : 'Stock: ${r.stock}'),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black26),
                      ),
                      if (esJefe) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.add_shopping_cart, size: 20),
                      ],
                    ],
                  ),
                  // Solo el Jefe puede comprar más stock.
                  onTap: esJefe ? () => _comprar(r) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
