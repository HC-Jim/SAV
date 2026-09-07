import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../widgets/buscar_reserva.dart';

/// Cajero — Devolver Garantía. «include» Buscar Orden de Reserva.
/// Lista las reservas en estado RESERVADO, se elige una y se devuelve la
/// garantía (con deducciones opcionales) → FINALIZADA.
class DevolverGarantiaScreen extends StatefulWidget {
  const DevolverGarantiaScreen({super.key});
  @override
  State<DevolverGarantiaScreen> createState() => _DevolverGarantiaScreenState();
}

class _DevolverGarantiaScreenState extends State<DevolverGarantiaScreen> {
  final _svc = AlquilerService();
  int _reload = 0;

  Future<void> _devolver(Reserva r) async {
    final ded = TextEditingController(text: '0');
    final deducciones = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Devolver garantía · Reserva #${r.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Garantía retenida: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: ded,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Deducciones por daños (S/)'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Se devuelve la garantía menos las deducciones y se emite el comprobante.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ded.text.trim()) ?? 0),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );
    if (deducciones == null) return;
    try {
      await _svc.devolverGarantia(r.id, deducciones: deducciones);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Garantía devuelta. Reserva finalizada.')));
      setState(() => _reload++);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devolver garantía')),
      body: BuscarReserva(
        estados: const {EstadoReserva.reservado},
        accionLabel: 'Devolver',
        accionIcono: Icons.assignment_return_outlined,
        reloadToken: _reload,
        onSeleccionar: _devolver,
      ),
    );
  }
}
