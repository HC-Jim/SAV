import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/alquiler_service.dart';
import '../../state/auth_controller.dart';

/// Detalle del vehículo + selección de fechas, disponibilidad y reserva.
class DetalleVehiculoScreen extends StatefulWidget {
  final Vehiculo vehiculo;
  const DetalleVehiculoScreen({super.key, required this.vehiculo});

  @override
  State<DetalleVehiculoScreen> createState() => _DetalleVehiculoScreenState();
}

class _DetalleVehiculoScreenState extends State<DetalleVehiculoScreen> {
  final _svc = AlquilerService();
  DateTime? _inicio;
  DateTime? _fin;
  String? _mensajeDisp;
  bool _disponible = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    // Periodo por defecto: 3 días desde hoy.
    _inicio = DateTime.now();
    _fin = _inicio!.add(const Duration(days: Vehiculo.diasPorDefecto));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha({required bool inicio}) async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? hoy : (_inicio ?? hoy),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _inicio = d;
      } else {
        _fin = d;
      }
      _mensajeDisp = null;
      _disponible = false;
    });
  }

  Future<void> _verDisponibilidad() async {
    if (_inicio == null || _fin == null) {
      _snack('Selecciona fecha de inicio y fin');
      return;
    }
    setState(() => _procesando = true);
    try {
      final r = await _svc.disponibilidad(widget.vehiculo.id, _fmt(_inicio!), _fmt(_fin!));
      setState(() {
        _disponible = r['disponible'] == true;
        _mensajeDisp = _disponible ? 'Disponible en esas fechas' : (r['motivo'] ?? 'No disponible');
      });
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final v = widget.vehiculo;
    return Scaffold(
      appBar: AppBar(title: Text('${v.marca ?? ''} ${v.modelo ?? ''}'.trim())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fila('Placa', v.placa),
                  _fila('Marca', v.marca ?? '-'),
                  _fila('Modelo', v.modelo ?? '-'),
                  _fila('Año', '${v.anio ?? '-'}'),
                  _fila('Color', v.color ?? '-'),
                  _fila('SKU', v.sku ?? '-'),
                  _fila('Categoría', v.categoria ?? '-'),
                  _fila('Precio de alquiler',
                      'S/ ${v.precioAlquiler.toStringAsFixed(2)} (${Vehiculo.diasPorDefecto} días)'),
                  _fila('Garantía', 'S/ ${v.garantia.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Periodo de alquiler', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _elegirFecha(inicio: true),
                  child: Text(_inicio == null ? 'Fecha inicio' : _fmt(_inicio!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _elegirFecha(inicio: false),
                  child: Text(_fin == null ? 'Fecha fin' : _fmt(_fin!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _procesando ? null : _verDisponibilidad,
            child: const Text('Ver disponibilidad'),
          ),
          if (_mensajeDisp != null) ...[
            const SizedBox(height: 12),
            Text(_mensajeDisp!,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: _disponible ? FontWeight.bold : FontWeight.normal)),
          ],
          if (_inicio != null && _fin != null) _resumenEstimado(),
          const SizedBox(height: 16),
          if (context.watch<AuthController>().usuario?.esCliente ?? false) ...[
            FilledButton.icon(
              onPressed: (_procesando || !_disponible) ? null : _generarOrdenReserva,
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Generar orden de reserva'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica la disponibilidad y genera tu orden de reserva. Luego, en '
              '"Mis reservas", paga la garantía y el alquiler para confirmarla.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generarOrdenReserva() async {
    if (_inicio == null || _fin == null) {
      _snack('Selecciona fecha de inicio y fin');
      return;
    }
    setState(() => _procesando = true);
    try {
      await _svc.generarOrdenReserva(
        vehiculoId: widget.vehiculo.id,
        fechaInicio: _fmt(_inicio!),
        fechaFin: _fmt(_fin!),
      );
      if (!mounted) return;
      _snack('Orden de reserva generada. Págala en "Mis reservas".');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  /// Resumen del costo (precio de alquiler fijo + garantía fija).
  Widget _resumenEstimado() {
    final v = widget.vehiculo;
    final dias = _fin!.difference(_inicio!).inDays <= 0
        ? Vehiculo.diasPorDefecto
        : _fin!.difference(_inicio!).inDays;
    final alquiler = v.precioAlquiler; // precio fijo, no depende de los días
    final garantia = v.garantia;
    final total = alquiler + garantia;
    Widget fila(String k, String val, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k,
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
              Text(val,
                  style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: const Color(0xFFF3F6FA),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen estimado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              fila('Días', '$dias'),
              fila('Precio de alquiler', 'S/ ${alquiler.toStringAsFixed(2)}'),
              fila('Garantía (depósito)', 'S/ ${garantia.toStringAsFixed(2)}'),
              const Divider(),
              fila('Total a pagar', 'S/ ${total.toStringAsFixed(2)}', bold: true),
              const SizedBox(height: 4),
              const Text(
                'La garantía es un depósito reembolsable al devolver el vehículo.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(String k, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(val)),
        ]),
      );
}
