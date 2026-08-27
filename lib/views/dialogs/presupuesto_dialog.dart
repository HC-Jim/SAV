import 'package:flutter/material.dart';
import '../../models/orden_mantenimiento.dart';

/// Generar presupuesto (Mecánico), a pantalla completa. El Mecánico solo
/// ingresa el costo de mano de obra; los repuestos provienen del requerimiento
/// YA APROBADO (con su cantidad aprobada). Devuelve { costo_mano_obra } o null.
Future<Map<String, dynamic>?> mostrarPresupuestoDialog(
    BuildContext context, OrdenMantenimiento orden) {
  return Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PresupuestoScreen(orden: orden),
    ),
  );
}

class _PresupuestoScreen extends StatefulWidget {
  final OrdenMantenimiento orden;
  const _PresupuestoScreen({required this.orden});
  @override
  State<_PresupuestoScreen> createState() => _PresupuestoScreenState();
}

class _PresupuestoScreenState extends State<_PresupuestoScreen> {
  final _manoObra = TextEditingController(text: '0');

  @override
  void dispose() {
    _manoObra.dispose();
    super.dispose();
  }

  List<RepuestoItem> get _items {
    final aprob = widget.orden.requerimientos.where((r) => r.estado == 'APROBADO');
    return aprob.isEmpty ? const [] : aprob.first.items;
  }

  double get _totalRepuestos =>
      _items.fold(0.0, (a, it) => a + it.precioUnitario * it.cantidad);

  void _guardar() {
    Navigator.pop(context, {
      'costo_mano_obra': double.tryParse(_manoObra.text.trim()) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final manoObra = double.tryParse(_manoObra.text.trim()) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Generar presupuesto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _manoObra,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo de mano de obra (S/)',
              prefixIcon: Icon(Icons.build),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('Repuestos aprobados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Card(
              child: ListTile(title: Text('Sin repuestos aprobados.')),
            )
          else
            Card(
              child: Column(
                children: _items
                    .map((it) => ListTile(
                          dense: true,
                          title: Text(it.nombre),
                          subtitle: Text(
                              '${it.cantidad} × S/ ${it.precioUnitario.toStringAsFixed(2)}'),
                          trailing: Text(
                              'S/ ${(it.precioUnitario * it.cantidad).toStringAsFixed(2)}'),
                        ))
                    .toList(),
              ),
            ),
          const Divider(height: 32),
          _fila('Repuestos', _totalRepuestos),
          _fila('Mano de obra', manoObra),
          _fila('Total', _totalRepuestos + manoObra, negrita: true),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.request_quote),
            label: const Text('Generar presupuesto'),
          ),
        ],
      ),
    );
  }

  Widget _fila(String k, double v, {bool negrita = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                    fontSize: negrita ? 16 : 14)),
            Text('S/ ${v.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                    fontSize: negrita ? 16 : 14)),
          ],
        ),
      );
}
