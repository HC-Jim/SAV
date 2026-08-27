import 'package:flutter/material.dart';
import '../services/alquiler_service.dart';
import '../services/api_client.dart';

/// «include» **Emitir/Ver Comprobante** — vista única de los comprobantes de
/// una reserva. Se abre igual desde cualquier acción del Cajero.
class VisorComprobantes {
  /// Carga y muestra los comprobantes de la reserva en un diálogo consistente.
  static Future<void> abrir(BuildContext context, {required int reservaId}) async {
    try {
      final lista = await AlquilerService().comprobantes(reservaId);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Comprobantes · Reserva #$reservaId'),
          content: lista.isEmpty
              ? const Text('Sin comprobantes.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lista
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      '${c['tipo'] ?? 'BOLETA'} — S/ ${((c['monto_total'] as num?) ?? 0).toStringAsFixed(2)}'),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
      }
    }
  }
}
