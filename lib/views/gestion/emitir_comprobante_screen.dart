import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../widgets/buscar_reserva.dart';
import '../../widgets/visor_comprobantes.dart';

/// Cajero — Emitir Comprobante. «include» Buscar Orden de Reserva.
/// Lista las reservas ya pagadas (RESERVADO / FINALIZADA), se elige una y se
/// emite el comprobante del pago; luego se muestran los comprobantes.
class EmitirComprobanteScreen extends StatefulWidget {
  const EmitirComprobanteScreen({super.key});
  @override
  State<EmitirComprobanteScreen> createState() => _EmitirComprobanteScreenState();
}

class _EmitirComprobanteScreenState extends State<EmitirComprobanteScreen> {
  final _svc = AlquilerService();
  int _reload = 0;

  Future<void> _emitir(Reserva r) async {
    try {
      await _svc.emitirComprobante(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comprobante emitido')));
      await VisorComprobantes.abrir(context, reservaId: r.id);
      if (mounted) setState(() => _reload++);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emitir comprobante')),
      body: BuscarReserva(
        estados: const {EstadoReserva.reservado, EstadoReserva.finalizada},
        accionLabel: 'Emitir',
        accionIcono: Icons.receipt_long_outlined,
        reloadToken: _reload,
        onSeleccionar: _emitir,
      ),
    );
  }
}
