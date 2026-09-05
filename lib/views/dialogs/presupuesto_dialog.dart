import 'package:flutter/material.dart';
import '../../models/orden_mantenimiento.dart';

/// Generar presupuesto (Mecánico), a pantalla completa. Es una confirmación:
/// consolida los repuestos del requerimiento APROBADO y la mano de obra
/// APROBADA. Devuelve {} al generar o null si se cancela.
Future<Map<String, dynamic>?> mostrarPresupuestoDialog(
    BuildContext context, OrdenMantenimiento orden) {
  return Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PresupuestoScreen(orden: orden),
    ),
  );
}

class _PresupuestoScreen extends StatelessWidget {
  final OrdenMantenimiento orden;
  const _PresupuestoScreen({required this.orden});

  List<RepuestoItem> get _items =>
      orden.requerimientos.isEmpty ? const [] : orden.requerimientos.last.items;

  double get _totalRepuestos =>
      _items.fold(0.0, (a, it) => a + it.precioUnitario * it.cantidad);

  @override
  Widget build(BuildContext context) {
    final manoObra = orden.manoObra;
    final costoManoObra = manoObra?.costo ?? 0;
    final total = _totalRepuestos + costoManoObra;

    return Scaffold(
      appBar: AppBar(title: const Text('Generar presupuesto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Repuestos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Card(child: ListTile(title: Text('Sin repuestos aprobados.')))
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
          const SizedBox(height: 16),
          const Text('Mano de obra',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              dense: true,
              title: Text('S/ ${costoManoObra.toStringAsFixed(2)}'),
              subtitle: (manoObra?.observacion != null && manoObra!.observacion!.isNotEmpty)
                  ? Text(manoObra.observacion!)
                  : null,
            ),
          ),
          const Divider(height: 32),
          _fila('Repuestos', _totalRepuestos),
          _fila('Mano de obra', costoManoObra),
          _fila('Total', total, negrita: true),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, <String, dynamic>{}),
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
