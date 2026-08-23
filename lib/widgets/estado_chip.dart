import 'package:flutter/material.dart';
import '../models/orden_mantenimiento.dart';
import '../theme.dart';

/// Chip de color que muestra el estado legible de una orden.
class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        EstadoOrden.legible(estado),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
