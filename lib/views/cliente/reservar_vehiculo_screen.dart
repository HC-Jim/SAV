import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../widgets/selector_vehiculo.dart';

/// Generar Orden de Reserva (Cliente).
/// Interfaz del caso de uso: primero se muestra la pantalla y, mediante el
/// caso de uso incluido «Buscar Vehículo», el Cliente selecciona el auto;
/// luego se muestran sus datos, el periodo y el resumen para generar la orden.
class ReservarVehiculoScreen extends StatefulWidget {
  const ReservarVehiculoScreen({super.key});
  @override
  State<ReservarVehiculoScreen> createState() => _ReservarVehiculoScreenState();
}

class _ReservarVehiculoScreenState extends State<ReservarVehiculoScreen> {
  final _svc = AlquilerService();
  Vehiculo? _sel;
  DateTime? _inicio;
  DateTime? _fin;
  String? _mensajeDisp;
  bool _disponible = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _inicio = DateTime.now();
    _fin = _inicio!.add(const Duration(days: Vehiculo.diasPorDefecto));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _elegirFecha({required bool inicio}) async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? (_inicio ?? hoy) : (_fin ?? hoy),
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
    if (_sel == null) {
      _snack('Primero busca y selecciona un vehículo');
      return;
    }
    if (_inicio == null || _fin == null) {
      _snack('Selecciona fecha de inicio y fin');
      return;
    }
    setState(() => _procesando = true);
    try {
      final r = await _svc.disponibilidad(_sel!.id, _fmt(_inicio!), _fmt(_fin!));
      setState(() {
        _disponible = r['disponible'] == true;
        _mensajeDisp =
            _disponible ? 'Disponible en esas fechas' : (r['motivo'] ?? 'No disponible');
      });
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _generarOrdenReserva() async {
    if (_sel == null || _inicio == null || _fin == null) return;
    setState(() => _procesando = true);
    try {
      await _svc.generarOrdenReserva(
        vehiculoId: _sel!.id,
        fechaInicio: _fmt(_inicio!),
        fechaFin: _fmt(_fin!),
      );
      if (!mounted) return;
      _snack('Orden de reserva generada. Págala en "Realizar pago".');
      setState(() {
        _sel = null;
        _disponible = false;
        _mensajeDisp = null;
      });
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _sel;
    return Scaffold(
      appBar: AppBar(title: const Text('Reservar vehículo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _sel,
            label: 'Buscar vehículo *',
            soloDisponibles: true,
            onChanged: (veh) => setState(() {
              _sel = veh;
              _disponible = false;
              _mensajeDisp = null;
            }),
          ),
          const SizedBox(height: 16),
          if (v == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Busca y selecciona un vehículo para reservarlo.',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else ...[
            _datosVehiculo(v),
            const SizedBox(height: 16),
            const Text('Periodo de alquiler',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                      fontWeight:
                          _disponible ? FontWeight.bold : FontWeight.normal)),
            ],
            _resumenEstimado(v),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_procesando || !_disponible) ? null : _generarOrdenReserva,
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Generar orden de reserva'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica la disponibilidad y genera tu orden de reserva. Luego, en '
              '"Realizar pago", paga la garantía y el alquiler para confirmarla.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _datosVehiculo(Vehiculo v) => Card(
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
      );

  Widget _resumenEstimado(Vehiculo v) {
    final dias = (_inicio != null && _fin != null && _fin!.difference(_inicio!).inDays > 0)
        ? _fin!.difference(_inicio!).inDays
        : Vehiculo.diasPorDefecto;
    final alquiler = v.precioAlquiler;
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
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
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
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(val)),
        ]),
      );
}
