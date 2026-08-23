import 'package:flutter/material.dart';

/// Formulario de inspección (Mecánico). Devuelve el cuerpo para el backend
/// o null si se cancela.
Future<Map<String, dynamic>?> mostrarInspeccionDialog(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const _InspeccionDialog(),
  );
}

class _InspeccionDialog extends StatefulWidget {
  const _InspeccionDialog();
  @override
  State<_InspeccionDialog> createState() => _InspeccionDialogState();
}

class _InspeccionDialogState extends State<_InspeccionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnostico = TextEditingController();
  final _kilometraje = TextEditingController();
  final _combustible = TextEditingController();
  final _observaciones = TextEditingController();
  final _justificacion = TextEditingController();
  String _resultado = 'CON_HALLAZGOS';
  bool _necesitaRepuestos = false;

  @override
  void dispose() {
    _diagnostico.dispose();
    _kilometraje.dispose();
    _combustible.dispose();
    _observaciones.dispose();
    _justificacion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'diagnostico': _diagnostico.text.trim(),
      'resultado': _resultado,
      'necesita_repuestos': _necesitaRepuestos,
      'kilometraje_lectura': int.tryParse(_kilometraje.text.trim()),
      'nivel_combustible': _combustible.text.trim().isEmpty ? null : _combustible.text.trim(),
      'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
      'justificacion': _resultado == 'POSTERGADA' ? _justificacion.text.trim() : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final postergada = _resultado == 'POSTERGADA';
    return AlertDialog(
      title: const Text('Registrar inspección'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _resultado,
                  decoration: const InputDecoration(labelText: 'Resultado'),
                  items: const [
                    DropdownMenuItem(value: 'CON_HALLAZGOS', child: Text('Con hallazgos')),
                    DropdownMenuItem(value: 'SIN_HALLAZGOS', child: Text('Sin hallazgos')),
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Indica el motivo' : null,
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('¿Necesita repuestos?'),
                    value: _necesitaRepuestos,
                    onChanged: (v) => setState(() => _necesitaRepuestos = v),
                  ),
                ],
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
