import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';
import '../../widgets/selector_vehiculo.dart';

/// Registrar Precio Vehicular — «include» Buscar Vehículo.
/// Cada registro se guarda con patrón cabecera/detalle (precio_vehiculo +
/// detalle_precio_vehiculo: ALQUILER, GARANTIA y COSTO). Muestra el precio
/// actual, el margen (ganancia/pérdida) frente al costo y el historial.
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
  final _costo = TextEditingController();
  Map<String, dynamic>? _stats;
  bool _guardando = false;
  bool _cargandoHist = false;

  @override
  void dispose() {
    _precio.dispose();
    _garantia.dispose();
    _costo.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  double get _alquilerInput => double.tryParse(_precio.text.trim()) ?? 0;
  double get _costoInput => double.tryParse(_costo.text.trim()) ?? 0;
  double get _margenInput => _alquilerInput - _costoInput;

  Future<void> _seleccionar(Vehiculo v) async {
    setState(() {
      _sel = v;
      _precio.text = v.precioAlquiler.toStringAsFixed(2);
      _garantia.text = v.garantia.toStringAsFixed(2);
      _costo.text = '';
      _stats = null;
    });
    await _cargarHistorial(v.id, autollenarCosto: true);
  }

  Future<void> _cargarHistorial(int id, {bool autollenarCosto = false}) async {
    setState(() => _cargandoHist = true);
    try {
      final s = await _svc.historialPrecios(id);
      if (!mounted) return;
      setState(() {
        _stats = s;
        if (autollenarCosto) {
          final c = (s['ultimo_costo'] as num?)?.toDouble() ?? 0;
          _costo.text = c.toStringAsFixed(2);
        }
      });
    } on ApiException catch (e) {
      _snack(e.mensaje);
    } finally {
      if (mounted) setState(() => _cargandoHist = false);
    }
  }

  Future<void> _registrar() async {
    if (_sel == null) return;
    final precio = _alquilerInput;
    final garantia = double.tryParse(_garantia.text.trim()) ?? 0;
    final costo = _costoInput;
    if (precio < 0 || garantia < 0 || costo < 0) {
      _snack('Los montos no pueden ser negativos');
      return;
    }
    setState(() => _guardando = true);
    try {
      // El costo no se envía: el backend reutiliza el costo fijado en la compra.
      await _svc.actualizarPrecioVehiculo(_sel!.id, {
        'precio_normal': precio,
        'garantia': garantia,
      });
      if (!mounted) return;
      _snack('Precio registrado');
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
            // El costo se fija en la compra: aquí solo se muestra (bloqueado).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _costo,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Precio costo (S/) — se fija en la compra',
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
            ),
            _evaluacionMargen(),
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

  /// Evaluación en vivo del margen (alquiler - costo).
  Widget _evaluacionMargen() {
    final m = _margenInput;
    final pct = _costoInput > 0 ? (m / _costoInput) * 100 : 0;
    final pctTxt = '${pct.toStringAsFixed(1)}%';
    final Color color;
    final String etiqueta;
    if (_costoInput <= 0) {
      color = Colors.black54;
      etiqueta = 'Costo no definido: se fija en la compra';
    } else if (m > 0) {
      color = Colors.green.shade700;
      etiqueta = '✔ Buen precio · Ganancia S/ ${m.toStringAsFixed(2)} ($pctTxt)';
    } else if (m == 0) {
      color = Colors.orange.shade800;
      etiqueta = 'Sin margen (cubre el costo justo · $pctTxt)';
    } else {
      color = Colors.red.shade700;
      etiqueta = '✖ Pérdida S/ ${m.abs().toStringAsFixed(2)} ($pctTxt) · por debajo del costo';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(etiqueta,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _cardActual(Vehiculo v) {
    final s = _stats;
    final promedio = (s?['promedio'] as num?)?.toDouble();
    final variacion = (s?['variacion'] as num?)?.toDouble();
    final variacionPct = (s?['variacion_pct'] as num?)?.toDouble();
    final costoActual = (s?['ultimo_costo'] as num?)?.toDouble();
    final margenActual = (s?['margen_actual'] as num?)?.toDouble();
    final margenActualPct = (s?['margen_actual_pct'] as num?)?.toDouble();
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
            if (costoActual != null) _fila('Costo actual', 'S/ ${costoActual.toStringAsFixed(2)}'),
            if (margenActual != null)
              _fila('Margen actual',
                  'S/ ${margenActual.toStringAsFixed(2)}'
                  '${margenActualPct != null ? ' (${margenActualPct.toStringAsFixed(1)}%)' : ''}',
                  color: margenActual > 0
                      ? Colors.green.shade700
                      : (margenActual < 0 ? Colors.red.shade700 : Colors.orange.shade800)),
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
    final items = hist.reversed.toList();
    return Column(
      children: items.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final fecha = (m['fecha']?.toString() ?? '').replaceFirst('T', ' ');
        final fechaCorta = fecha.length >= 16 ? fecha.substring(0, 16) : fecha;
        final alquiler = (m['alquiler'] as num?)?.toDouble() ?? 0;
        final garantia = (m['garantia'] as num?)?.toDouble() ?? 0;
        final costo = (m['costo'] as num?)?.toDouble() ?? 0;
        final margen = (m['margen'] as num?)?.toDouble() ?? 0;
        final margenPct = (m['margen_pct'] as num?)?.toDouble() ?? 0;
        final quien = m['registrado_por'];
        final colorM = margen > 0
            ? Colors.green.shade700
            : (margen < 0 ? Colors.red.shade700 : Colors.orange.shade800);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: Text('Alquiler: S/ ${alquiler.toStringAsFixed(2)}  ·  '
                'Costo: S/ ${costo.toStringAsFixed(2)}'),
            subtitle: Text('Garantía: S/ ${garantia.toStringAsFixed(2)}  ·  '
                '$fechaCorta${quien != null ? '  ·  por $quien' : ''}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${margen >= 0 ? '+' : '-'}S/ ${margen.abs().toStringAsFixed(2)}',
                    style: TextStyle(color: colorM, fontWeight: FontWeight.bold)),
                Text('${margenPct.toStringAsFixed(1)}%',
                    style: TextStyle(color: colorM, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _fila(String k, String val, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.black87)),
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label),
        ),
      );
}
