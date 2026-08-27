import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/cotizacion.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/ventas_service.dart';
import '../../widgets/selector_cliente.dart';
import '../../widgets/selector_vehiculo.dart';

/// Cotizaciones (Asesor de Ventas): generar, solicitar garantía y generar orden de reserva.
class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});
  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final _svc = VentasService();
  late Future<List<Cotizacion>> _futuro;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarTodas());

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
        title: const Text('Cotizaciones'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
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
                if (lista.isEmpty) return const Center(child: Text('Sin cotizaciones.'));
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
            Text('${c.clienteDesc}  ·  ${c.vehiculoDesc}'),
            Text('Del ${c.fechaInicio ?? '-'} al ${c.fechaFin ?? '-'}  ·  '
                'Total S/ ${c.montoTotalEstimado.toStringAsFixed(2)}  ·  '
                'Garantía S/ ${c.garantiaMonto.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _acciones(c)),
          ],
        ),
      ),
    );
  }

  List<Widget> _acciones(Cotizacion c) {
    final acciones = <Widget>[];
    if (c.estado == EstadoCotizacion.aceptada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.solicitarGarantia(c.id)),
        child: const Text('Solicitar garantía'),
      ));
    }
    if (c.estado == EstadoCotizacion.garantiaPagada) {
      acciones.add(FilledButton(
        onPressed: _procesando ? null : () => _ejecutar(() => _svc.generarReserva(c.id)),
        child: const Text('Generar orden de reserva'),
      ));
    }
    return acciones;
  }

  Future<void> _abrirForm() async {
    Cliente? clienteSel;
    Vehiculo? vehiculoSel;
    DateTime? inicio;
    DateTime? fin;
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nueva cotización'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SelectorCliente(
                value: clienteSel,
                onChanged: (c) => setLocal(() => clienteSel = c),
              ),
              const SizedBox(height: 10),
              SelectorVehiculo(
                value: vehiculoSel,
                soloDisponibles: true,
                onChanged: (v) => setLocal(() => vehiculoSel = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setLocal(() => inicio = d);
                    },
                    child: Text(inicio == null ? 'Fecha inicio' : fmt(inicio!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: inicio ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setLocal(() => fin = d);
                    },
                    child: Text(fin == null ? 'Fecha fin' : fmt(fin!)),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Generar')),
          ],
        ),
      ),
    );

    if (ok == true && clienteSel != null && vehiculoSel != null && inicio != null && fin != null) {
      _ejecutar(() => _svc.generar(
            clienteId: clienteSel!.id,
            vehiculoId: vehiculoSel!.id,
            fechaInicio: fmt(inicio!),
            fechaFin: fmt(fin!),
          ));
    } else if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Completa cliente, vehículo y fechas')));
    }
  }
}
