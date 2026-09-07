import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';

/// Pantalla de pago de una Orden de Reserva (garantía + alquiler).
/// Devuelve true si el pago se realizó.
class PagarReservaScreen extends StatefulWidget {
  final Reserva reserva;
  const PagarReservaScreen({super.key, required this.reserva});

  @override
  State<PagarReservaScreen> createState() => _PagarReservaScreenState();
}

class _PagarReservaScreenState extends State<PagarReservaScreen> {
  final _svc = AlquilerService();
  String _metodo = 'TARJETA';
  bool _procesando = false;

  double get _alquiler => widget.reserva.montoTotalEstimado;
  double get _garantia => widget.reserva.garantiaMonto;
  double get _total => _alquiler + _garantia;

  Future<void> _pagar() async {
    setState(() => _procesando = true);
    try {
      await _svc.pagarOrdenReserva(widget.reserva.id, metodo: _metodo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago realizado. Reserva confirmada.')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final v = r.vehiculo;
    return Scaffold(
      appBar: AppBar(title: Text('Pagar reserva #${r.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Datos de la reserva
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v != null
                        ? '${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})'.trim()
                        : 'Vehículo ${r.vehiculoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}',
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Desglose del pago
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _fila('Alquiler', _alquiler),
                  _fila('Garantía (depósito reembolsable)', _garantia),
                  const Divider(),
                  _fila('Total a pagar', _total, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Método de pago
          const Text('Método de pago',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'TARJETA', label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
              ButtonSegment(value: 'EFECTIVO', label: Text('Efectivo'), icon: Icon(Icons.payments_outlined)),
            ],
            selected: {_metodo},
            onSelectionChanged: (s) => setState(() => _metodo = s.first),
          ),
          const SizedBox(height: 12),
          const Text(
            'La garantía es un depósito que se te devuelve al entregar el vehículo, '
            'menos deducciones por daños si las hubiera.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _procesando ? null : _pagar,
            icon: const Icon(Icons.lock_outline),
            label: Text(_procesando
                ? 'Procesando...'
                : 'Pagar S/ ${_total.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }

  Widget _fila(String k, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('S/ ${v.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}
