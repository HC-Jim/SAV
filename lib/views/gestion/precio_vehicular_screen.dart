import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Registrar Precio Vehicular — «include» Buscar Vehículo.
/// Cada registro se guarda con patrón cabecera/detalle (precio_vehiculo +
/// detalle_precio_vehiculo). Muestra el precio actual, permite registrar un
/// nuevo precio y lista el historial de precios realizados.
class PrecioVehicularScreen extends StatefulWidget {
  const PrecioVehicularScreen({super.key});
  @override
  State<PrecioVehicularScreen> createState() => _PrecioVehicularScreenState();
}

class _PrecioVehicularScreenState extends State<PrecioVehicularScreen> {
  final _svc = GestionService();
  Vehiculo? _sel;
  final _precio = TextEditingController();
  final _garantia = TextEditingController();
  Map<String, dynamic>? _stats;
  bool _guardando = false;
  bool _cargandoHist = false;

  @override
  void dispose() {
    _precio.dispose();
    _garantia.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _seleccionar(Vehiculo v) async {
    setState(() {
      _sel = v;
      _precio.text = v.precioAlquiler.toStringAsFixed(2);
      _garantia.text = v.garantia.toStringAsFixed(2);
      _stats = null;
    });
    await _cargarHistorial(v.id);
  }

  Future<void> _cargarHistorial(int id) async {
    setState(() => _cargandoHist = true);
    try {
      final s = await _svc.historialPrecios(id);
      if (mounted) setState(() => _stats = s);
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _cargandoHist = false);
    }
  }

  Future<void> _registrar() async {
    if (_sel == null) return;
    final precio = double.tryParse(_precio.text.trim()) ?? 0;
    final garantia = double.tryParse(_garantia.text.trim()) ?? 0;
    if (precio < 0 || garantia < 0) {
      _snack('El precio y la garantía no pueden ser negativos');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _svc.actualizarPrecioVehiculo(
          _sel!.id, {'precio_normal': precio, 'garantia': garantia});
      if (!mounted) return;
      _snack('Precio registrado');
      // Actualiza el precio actual en memoria y recarga el historial.
      setState(() => _sel = Vehiculo(
            id: _sel!.id,
            sku: _sel!.sku,
            placa: _sel!.placa,
            marca: _sel!.marca,
            modelo: _sel!.modelo,
            anio: _sel!.anio,
            color: _sel!.color,
            categoria: _sel!.categoria,
            precioAlquiler: precio,
            garantia: garantia,
            kilometraje: _sel!.kilometraje,
            fechaProximoMantenimiento: _sel!.fechaProximoMantenimiento,
            estado: _sel!.estado,
          ));
      await _cargarHistorial(_sel!.id);
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _sel;
    return Scaffold(
      appBar: AppBar(title: const Text('Precio vehicular')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Vehículo
          SelectorVehiculo(
            value: _sel,
            label: 'Buscar vehículo',
            onChanged: _seleccionar,
          ),
          const SizedBox(height: 16),
          if (v == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Busca un vehículo para registrar y ver su precio.',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else ...[
            _cardActual(v),
            const SizedBox(height: 12),
            const Text('Registrar nuevo precio',
                style: TextStyle(fontWeight: FontWeight.bold)),
            _campo(_precio, 'Precio de alquiler (S/ por ${Vehiculo.diasPorDefecto} días)'),
            _campo(_garantia, 'Garantía / depósito (S/)'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _guardando ? null : _registrar,
              icon: const Icon(Icons.save),
              label: Text(_guardando ? 'Registrando...' : 'Registrar precio'),
            ),
            const SizedBox(height: 20),
            const Text('Historial de precios',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _historial(),
          ],
        ],
      ),
    );
  }

  Widget _cardActual(Vehiculo v) {
    final s = _stats;
    final promedio = (s?['promedio'] as num?)?.toDouble();
    final variacion = (s?['variacion'] as num?)?.toDouble();
    final variacionPct = (s?['variacion_pct'] as num?)?.toDouble();
    final cambios = (s?['cambios'] as num?)?.toInt();
    String varTexto() {
      if (variacion == null) return '—';
      if (variacion == 0) return 'sin variación';
      final signo = variacion > 0 ? '▲' : '▼';
      return '$signo S/ ${variacion.abs().toStringAsFixed(2)} '
          '(${(variacionPct ?? 0).toStringAsFixed(1)}%)';
    }

    return Card(
      color: const Color(0xFFF3F6FA),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.descripcion,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Categoría: ${v.categoria ?? '-'}  ·  ${v.estadoLegible}',
                style: const TextStyle(color: Colors.black54)),
            const Divider(),
            _fila('Precio de alquiler actual', 'S/ ${v.precioAlquiler.toStringAsFixed(2)}'),
            _fila('Garantía actual', 'S/ ${v.garantia.toStringAsFixed(2)}'),
            if (promedio != null) _fila('Precio promedio', 'S/ ${promedio.toStringAsFixed(2)}'),
            if (variacion != null) _fila('Variación total', varTexto()),
            if (cambios != null) _fila('N° de registros', '$cambios'),
          ],
        ),
      ),
    );
  }

  Widget _historial() {
    if (_cargandoHist) {
      return const Center(child: Padding(
          padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    final hist = (_stats?['historial'] as List?) ?? [];
    if (hist.isEmpty) {
      return const Text('Sin registros de precio.',
          style: TextStyle(color: Colors.black54));
    }
    // Más recientes primero.
    final items = hist.reversed.toList();
    return Column(
      children: items.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final fecha = (m['fecha']?.toString() ?? '').replaceFirst('T', ' ');
        final fechaCorta = fecha.length >= 16 ? fecha.substring(0, 16) : fecha;
        final alquiler = (m['alquiler'] as num?)?.toDouble() ?? 0;
        final garantia = (m['garantia'] as num?)?.toDouble() ?? 0;
        final quien = m['registrado_por'];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: Text('Alquiler: S/ ${alquiler.toStringAsFixed(2)}  ·  '
                'Garantía: S/ ${garantia.toStringAsFixed(2)}'),
            subtitle: Text('$fechaCorta${quien != null ? '  ·  por $quien' : ''}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _fila(String k, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.black87)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
