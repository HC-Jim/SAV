import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/alquiler_service.dart';

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
          const SizedBox(height: 16),
          const Text(
            'Para reservar este vehículo, acércate a un Asesor de Ventas: '
            'él generará tu cotización y luego podrás pagar la garantía desde "Mis cotizaciones".',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
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
