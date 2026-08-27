import 'package:flutter/material.dart';

/// Registrar mano de obra (Mecánico), a pantalla completa: costo + observación.
/// Devuelve { costo, observacion } o null si se cancela.
Future<Map<String, dynamic>?> mostrarManoObraDialog(BuildContext context) {
  return Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _ManoObraScreen(),
    ),
  );
}

class _ManoObraScreen extends StatefulWidget {
  const _ManoObraScreen();
  @override
  State<_ManoObraScreen> createState() => _ManoObraScreenState();
}

class _ManoObraScreenState extends State<_ManoObraScreen> {
  final _costo = TextEditingController(text: '0');
  final _observacion = TextEditingController();

  @override
  void dispose() {
    _costo.dispose();
    _observacion.dispose();
    super.dispose();
  }

  void _guardar() {
    final costo = double.tryParse(_costo.text.trim()) ?? 0;
    if (costo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un costo mayor a 0')));
      return;
    }
    Navigator.pop(context, {
      'costo': costo,
      'observacion': _observacion.text.trim().isEmpty ? null : _observacion.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar mano de obra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _costo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo de mano de obra (S/)',
              prefixIcon: Icon(Icons.build),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _observacion,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observación (opcional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save),
            label: const Text('Registrar mano de obra'),
          ),
        ],
      ),
    );
  }
}
