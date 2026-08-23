import 'package:flutter/material.dart';

/// Pide un motivo (texto) para las acciones de rechazo. Devuelve el motivo o null.
Future<String?> mostrarMotivoDialog(BuildContext context, String titulo) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Motivo'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}
