import 'package:flutter/material.dart';

/// Formulario del informe técnico (Mecánico). Devuelve el cuerpo o null.
Future<Map<String, dynamic>?> mostrarInformeDialog(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const _InformeDialog(),
  );
}

class _InformeDialog extends StatefulWidget {
  const _InformeDialog();
  @override
  State<_InformeDialog> createState() => _InformeDialogState();
}

class _InformeDialogState extends State<_InformeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _trabajos = TextEditingController();
  final _repuestos = TextEditingController();
  final _pruebas = TextEditingController();
  final _observaciones = TextEditingController();

  @override
  void dispose() {
    _trabajos.dispose();
    _repuestos.dispose();
    _pruebas.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'trabajos_realizados': _trabajos.text.trim(),
      'repuestos_instalados': _repuestos.text.trim(),
      'resultados_pruebas': _pruebas.text.trim(),
      'observaciones': _observaciones.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Informe técnico'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _trabajos,
                  decoration: const InputDecoration(labelText: 'Trabajos realizados'),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repuestos,
                  decoration: const InputDecoration(labelText: 'Repuestos instalados'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pruebas,
                  decoration: const InputDecoration(labelText: 'Resultados de pruebas'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observaciones,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
