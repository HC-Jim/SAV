import 'package:flutter/material.dart';
import '../../models/cotizacion.dart';
import '../../services/api_client.dart';
import '../../services/ventas_service.dart';

/// Cajero: garantías pagadas por los clientes, pendientes de aprobación.
/// Al aprobar se emite el comprobante de la garantía.
class GarantiasScreen extends StatefulWidget {
  const GarantiasScreen({super.key});
  @override
  State<GarantiasScreen> createState() => _GarantiasScreenState();
}

class _GarantiasScreenState extends State<GarantiasScreen> {
  final _svc = VentasService();
  late Future<List<Cotizacion>> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.garantiasPendientes());

  Future<void> _aprobar(Cotizacion c) async {
    setState(() => _procesando = true);
    try {
      await _svc.aprobarGarantia(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Garantía aprobada y comprobante emitido')));
      _cargar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colors.black));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garantías por aprobar'),
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
                  return const Center(child: Text('No hay garantías pendientes.'));
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
            Text('Cotización #${c.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(c.vehiculo?.descripcion ?? 'Vehículo ${c.vehiculoId}'),
            Text('Del ${c.fechaInicio ?? '-'} al ${c.fechaFin ?? '-'}  ·  ${c.dias} día(s)'),
            const SizedBox(height: 4),
            Text('Garantía pagada: S/ ${c.garantiaMonto.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _procesando ? null : () => _aprobar(c),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Aprobar y emitir comprobante'),
            ),
          ],
        ),
      ),
    );
  }
}
