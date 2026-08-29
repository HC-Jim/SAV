import 'package:flutter/material.dart';
import '../../models/cotizacion.dart';
import '../../services/api_client.dart';
import '../../services/ventas_service.dart';

/// Cotizaciones del Cliente: aceptar/rechazar y pagar garantía.
class MisCotizacionesScreen extends StatefulWidget {
  const MisCotizacionesScreen({super.key});
  @override
  State<MisCotizacionesScreen> createState() => _MisCotizacionesScreenState();
}

class _MisCotizacionesScreenState extends State<MisCotizacionesScreen> {
  final _svc = VentasService();
  late Future<List<Cotizacion>> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.mias());

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _procesando = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Operación realizada')));
      _cargar();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis cotizaciones'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: Column(
        children: [
          if (_procesando) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<Cotizacion>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                final lista = snap.data ?? [];
                if (lista.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no tienes cotizaciones.\nUn asesor de ventas debe generarte una.',
                      textAlign: TextAlign.center,
                    ),
                  ));
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: lista.map(_card).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Cotizacion c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cotización #${c.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(EstadoCotizacion.legible(c.estado),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(c.vehiculoDesc),
            Text('Del ${c.fechaInicio ?? '-'} al ${c.fechaFin ?? '-'}  ·  ${c.dias} día(s)'),
            const SizedBox(height: 4),
            Text('Total estimado: S/ ${c.montoTotalEstimado.toStringAsFixed(2)}'),
            Text('Garantía: S/ ${c.garantiaMonto.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _acciones(c)),
          ],
        ),
      ),
    );
  }

  List<Widget> _acciones(Cotizacion c) {
    final acciones = <Widget>[];
    if (c.estado == EstadoCotizacion.pendiente) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.decidir(c.id, true)),
        child: const Text('Aceptar'),
      ));
      acciones.add(OutlinedButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.decidir(c.id, false)),
        child: const Text('Rechazar'),
      ));
    }
    // Self-service: puede pagar tras aceptar o tras solicitud del asesor.
    if (c.estado == EstadoCotizacion.aceptada ||
        c.estado == EstadoCotizacion.garantiaSolicitada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.pagarGarantia(c.id)),
        child: const Text('Pagar garantía'),
      ));
    }
    if (c.estado == EstadoCotizacion.garantiaPagada) {
      acciones.add(const Chip(label: Text('Esperando aprobación del cajero')));
    }
    if (c.estado == EstadoCotizacion.garantiaAprobada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.generarReserva(c.id)),
        child: const Text('Generar reserva'),
      ));
    }
    return acciones;
  }
}
