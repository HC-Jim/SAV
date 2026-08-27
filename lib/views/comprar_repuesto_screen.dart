import 'package:flutter/material.dart';
import '../models/repuesto.dart';
import '../services/api_client.dart';
import '../services/mantenimiento_service.dart';

/// Comprar más stock de un repuesto del catálogo (Jefe de Logística).
class ComprarRepuestoScreen extends StatefulWidget {
  final Repuesto repuesto;
  const ComprarRepuestoScreen({super.key, required this.repuesto});

  @override
  State<ComprarRepuestoScreen> createState() => _ComprarRepuestoScreenState();
}

class _ComprarRepuestoScreenState extends State<ComprarRepuestoScreen> {
  final _svc = MantenimientoService();
  final _cantidad = TextEditingController(text: '1');
  bool _guardando = false;

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _comprar() async {
    final n = int.tryParse(_cantidad.text.trim()) ?? 0;
    if (n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa una cantidad mayor a 0')));
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.comprarRepuesto(widget.repuesto.id, n);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se compraron $n unidad(es)')));
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
    final r = widget.repuesto;
    return Scaffold(
      appBar: AppBar(title: const Text('Comprar repuesto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Ref: ${r.referencia ?? '-'}  ·  S/ ${r.costoUnitario.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Text('Stock actual: ${r.stock}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cantidad,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad a comprar',
              prefixIcon: Icon(Icons.add_shopping_cart),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _comprar,
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text(_guardando ? 'Comprando...' : 'Comprar'),
          ),
        ],
      ),
    );
  }
}
