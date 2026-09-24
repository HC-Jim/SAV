import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/selector_vehiculo.dart';

/// Catálogo de Precios — «include» Buscar Vehículo.
/// Se elige el vehículo con el buscador reutilizable y luego se ve/edita su
/// precio de alquiler fijo y su costo de garantía.
class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});
  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final _gestion = GestionService();
  Vehiculo? _sel;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.watch<AuthController>().usuario?.esAdministrador ?? false;
    final v = _sel;
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de precios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _sel,
            label: 'Buscar vehículo',
            onChanged: (veh) => setState(() => _sel = veh),
          ),
          const SizedBox(height: 16),
          if (v == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Busca y elige un vehículo para ver o editar su precio.',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Categoría: ${v.categoria ?? '-'}  ·  ${v.estadoLegible}',
                        style: const TextStyle(color: Colors.black54)),
                    const Divider(height: 24),
                    _fila('Precio de alquiler (${Vehiculo.diasPorDefecto} días)',
                        'S/ ${v.precioAlquiler.toStringAsFixed(2)}'),
                    _fila('Garantía (depósito)', 'S/ ${v.garantia.toStringAsFixed(2)}'),
                    if (esAdmin) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _editar(v),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar precio y garantía'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fila(String k, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.black87)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Future<void> _editar(Vehiculo v) async {
    final precio = TextEditingController(text: v.precioAlquiler.toStringAsFixed(2));
    final garantia = TextEditingController(text: v.garantia.toStringAsFixed(2));

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Precio · ${v.placa}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _campo(precio, 'Precio de alquiler (S/ por ${Vehiculo.diasPorDefecto} días)'),
          _campo(garantia, 'Garantía / depósito (S/)'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'precio_normal': double.tryParse(precio.text.trim()) ?? 0,
              'garantia': double.tryParse(garantia.text.trim()) ?? 0,
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (datos == null) return;
    try {
      await _gestion.actualizarPrecioVehiculo(v.id, datos);
      if (!mounted) return;
      // Refleja los nuevos valores en la tarjeta.
      setState(() => _sel = Vehiculo(
            id: v.id,
            sku: v.sku,
            placa: v.placa,
            marca: v.marca,
            modelo: v.modelo,
            anio: v.anio,
            color: v.color,
            categoria: v.categoria,
            precioAlquiler: datos['precio_normal'] as double,
            garantia: datos['garantia'] as double,
            kilometraje: v.kilometraje,
            fechaProximoMantenimiento: v.fechaProximoMantenimiento,
            estado: v.estado,
          ));
      _snack('Precio actualizado');
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
