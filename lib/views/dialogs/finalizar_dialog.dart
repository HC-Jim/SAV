import 'package:flutter/material.dart';

/// Finalizar mantenimiento: captura una observación con los puntos clave del
/// proceso de ejecución. Devuelve el texto (puede ir vacío) o null si cancela.
Future<String?> mostrarFinalizarDialog(BuildContext context) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Finalizar mantenimiento'),
      content: TextField(
        controller: ctrl,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Observación (puntos clave de la ejecución)',
          hintText: 'Ej. Se cambiaron filtros y aceite; frenos revisados…',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
          child: const Text('Finalizar'),
        ),
      ],
    ),
  );
}
