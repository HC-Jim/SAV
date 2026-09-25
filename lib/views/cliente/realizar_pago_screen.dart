import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../services/alquiler_service.dart';
import '../../services/api_client.dart';
import '../../services/pdf_generator.dart';
import '../../widgets/selector_reserva.dart';

/// Registrar Pago de Orden de Reserva (Cliente).
/// Interfaz del caso de uso: primero se muestra la pantalla y, mediante el
/// caso de uso incluido «Buscar Reserva», el Cliente elige la reserva a pagar.
/// Admite pago con Tarjeta (crédito/débito, cuotas) o Yape, aplicación de un
/// cupón de descuento y la emisión del comprobante.
class RealizarPagoScreen extends StatefulWidget {
  const RealizarPagoScreen({super.key});
  @override
  State<RealizarPagoScreen> createState() => _RealizarPagoScreenState();
}

class _RealizarPagoScreenState extends State<RealizarPagoScreen> {
  final _svc = AlquilerService();

  Reserva? _reserva;
  Map<String, dynamic>? _cupon; // {codigo, tipo, valor, descuento}
  String _metodo = 'TARJETA';
  String _tipoTarjeta = 'DEBITO';
  int _cuotas = 3;
  bool _procesando = false;
  bool _validandoCupon = false;

  final _cuponCtrl = TextEditingController();
  final _numero = TextEditingController();
  final _cvv = TextEditingController();
  final _venc = TextEditingController();
  String _marca = 'VISA';
  final _yapeCel = TextEditingController();
  final _yapeOp = TextEditingController();

  static const _marcas = ['VISA', 'MASTERCARD', 'AMEX', 'OTRA'];
  static const _opcionesCuotas = [3, 6, 9, 12, 18, 24];

  @override
  void dispose() {
    for (final c in [_cuponCtrl, _numero, _cvv, _venc, _yapeCel, _yapeOp]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _alquiler => _reserva?.montoTotalEstimado ?? 0;
  double get _garantia => _reserva?.garantiaMonto ?? 0;
  double get _descuento => (_cupon?['descuento'] as num?)?.toDouble() ?? 0;
  double get _alquilerFinal =>
      (_alquiler - _descuento) < 0 ? 0 : (_alquiler - _descuento);
  double get _total => _alquilerFinal + _garantia;

  void _snack(String m, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? Colors.black : null,
      ));

  String _soloDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

  // ---------------- Cupón ----------------
  Future<void> _validarCupon() async {
    final codigo = _cuponCtrl.text.trim();
    if (codigo.isEmpty) {
      _snack('Ingresa un código de cupón');
      return;
    }
    setState(() => _validandoCupon = true);
    try {
      final r = await _svc.validarCupon(_reserva!.id, codigo);
      setState(() => _cupon = r);
      _snack('Cupón aplicado: -S/ ${_descuento.toStringAsFixed(2)}');
    } on ApiException catch (e) {
      setState(() => _cupon = null);
      _snack(e.mensaje, error: true);
    } finally {
      if (mounted) setState(() => _validandoCupon = false);
    }
  }

  void _quitarCupon() => setState(() {
        _cupon = null;
        _cuponCtrl.clear();
      });

  // ---------------- Pago ----------------
  String? _validarMedio() {
    if (_metodo == 'TARJETA') {
      final num = _soloDigitos(_numero.text);
      if (num.length < 13 || num.length > 19) {
        return 'Ingresa un número de tarjeta válido';
      }
      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_venc.text.trim())) {
        return 'Vencimiento con formato MM/AA';
      }
      if (_soloDigitos(_cvv.text).length < 3) return 'CVV inválido';
    } else {
      if (_soloDigitos(_yapeCel.text).length != 9) {
        return 'Celular Yape de 9 dígitos';
      }
      if (_yapeOp.text.trim().isEmpty) return 'Ingresa el N° de operación Yape';
    }
    return null;
  }

  Future<void> _pagar() async {
    final err = _validarMedio();
    if (err != null) {
      _snack(err, error: true);
      return;
    }
    setState(() => _procesando = true);
    try {
      final num = _soloDigitos(_numero.text);
      final resp = await _svc.pagarOrdenReserva(
        _reserva!.id,
        metodo: _metodo,
        tipoTarjeta: _metodo == 'TARJETA' ? _tipoTarjeta : null,
        cuotas: (_metodo == 'TARJETA' && _tipoTarjeta == 'CREDITO') ? _cuotas : null,
        tarjetaUltimos4: _metodo == 'TARJETA' && num.length >= 4
            ? num.substring(num.length - 4)
            : null,
        tarjetaMarca: _metodo == 'TARJETA' ? _marca : null,
        yapeCelular: _metodo == 'YAPE' ? _soloDigitos(_yapeCel.text) : null,
        yapeOperacion: _metodo == 'YAPE' ? _yapeOp.text.trim() : null,
        cuponCodigo: _cupon?['codigo'] as String?,
      );
      if (!mounted) return;
      await _mostrarComprobante(resp);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _snack(e.mensaje, error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _mostrarComprobante(Map<String, dynamic> resp) async {
    final total = (resp['total'] as num?)?.toDouble() ?? _total;
    final descuento = (resp['descuento'] as num?)?.toDouble() ?? _descuento;
    final vehiculo = _reserva?.vehiculo?.descripcion ?? 'Vehículo ${_reserva?.vehiculoId}';
    final detalleMetodo = _metodo == 'TARJETA'
        ? '$_marca · ${_tipoTarjeta == 'CREDITO' ? 'Crédito $_cuotas cuotas' : 'Débito'}'
        : 'Yape';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: const Text('Pago realizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserva #${_reserva!.id} confirmada.'),
            const SizedBox(height: 8),
            Text('Método: $detalleMetodo'),
            if (descuento > 0) Text('Descuento: -S/ ${descuento.toStringAsFixed(2)}'),
            Text('Total pagado: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('¿Deseas generar el comprobante de pago?',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await generarComprobantePdf(
                reservaId: _reserva!.id,
                vehiculo: vehiculo,
                alquiler: _alquiler,
                garantia: _garantia,
                descuento: descuento,
                total: total,
                metodo: _metodo == 'TARJETA' ? 'Tarjeta' : 'Yape',
                detalleMetodo: detalleMetodo,
                cupon: _cupon?['codigo'] as String?,
              );
              if (dctx.mounted) Navigator.pop(dctx);
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Comprobante'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realizar pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // «include» Buscar Reserva
          SelectorReserva(
            value: _reserva,
            label: 'Buscar reserva a pagar *',
            onChanged: (r) => setState(() {
              _reserva = r;
              _cupon = null;
              _cuponCtrl.clear();
            }),
          ),
          const SizedBox(height: 16),
          if (_reserva == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Busca y selecciona una reserva pendiente de pago.',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else ...[
            _resumen(),
            const SizedBox(height: 12),
            _seccionCupon(),
            const SizedBox(height: 12),
            _seccionMetodo(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _procesando ? null : _pagar,
              icon: const Icon(Icons.lock_outline),
              label: Text(_procesando
                  ? 'Procesando...'
                  : 'Pagar S/ ${_total.toStringAsFixed(2)}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resumen() {
    final r = _reserva!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.vehiculo?.descripcion ?? 'Vehículo ${r.vehiculoId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}',
                style: const TextStyle(color: Colors.black54)),
            const Divider(height: 24),
            _fila('Alquiler', _alquiler),
            if (_descuento > 0) _fila('Descuento (${_cupon?['codigo']})', -_descuento),
            _fila('Garantía (depósito reembolsable)', _garantia),
            const Divider(),
            _fila('Total a pagar', _total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _seccionCupon() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cupón de descuento',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_cupon != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cupón ${_cupon!['codigo']} aplicado: '
                        '-S/ ${_descuento.toStringAsFixed(2)}'
                        '${_cupon!['tipo'] == 'PORCENTAJE' ? ' (${_cupon!['valor']}%)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(onPressed: _quitarCupon, child: const Text('Quitar')),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cuponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Código de cupón',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _validandoCupon ? null : _validarCupon,
                      child: Text(_validandoCupon ? '...' : 'Validar'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

  Widget _seccionMetodo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Método de pago',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'TARJETA', label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
                  ButtonSegment(value: 'YAPE', label: Text('Yape'), icon: Icon(Icons.qr_code_2)),
                ],
                selected: {_metodo},
                onSelectionChanged: (s) => setState(() => _metodo = s.first),
              ),
              const SizedBox(height: 12),
              if (_metodo == 'TARJETA') ..._camposTarjeta() else ..._camposYape(),
            ],
          ),
        ),
      );

  List<Widget> _camposTarjeta() => [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DEBITO', label: Text('Débito')),
            ButtonSegment(value: 'CREDITO', label: Text('Crédito')),
          ],
          selected: {_tipoTarjeta},
          onSelectionChanged: (s) => setState(() => _tipoTarjeta = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _numero,
          keyboardType: TextInputType.number,
          maxLength: 19,
          decoration: const InputDecoration(
            labelText: 'Número de tarjeta',
            hintText: '1234 5678 9012 3456',
            counterText: '',
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _venc,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: 'Vencimiento (MM/AA)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _marca,
          decoration: const InputDecoration(labelText: 'Marca'),
          items: _marcas
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _marca = v ?? _marca),
        ),
        if (_tipoTarjeta == 'CREDITO') ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _cuotas,
            decoration: const InputDecoration(labelText: 'Cuotas'),
            items: _opcionesCuotas
                .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text('$n cuotas · S/ ${(_total / n).toStringAsFixed(2)} c/u')))
                .toList(),
            onChanged: (v) => setState(() => _cuotas = v ?? _cuotas),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Por seguridad, solo se registran los últimos 4 dígitos y la marca. '
          'El CVV no se almacena.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ];

  List<Widget> _camposYape() => [
        TextField(
          controller: _yapeCel,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          decoration: const InputDecoration(
            labelText: 'Celular Yape',
            hintText: '9XXXXXXXX',
            counterText: '',
          ),
        ),
        TextField(
          controller: _yapeOp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'N° de operación Yape'),
        ),
      ];

  Widget _fila(String k, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('S/ ${v.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}
