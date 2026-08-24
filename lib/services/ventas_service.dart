import '../config/api_config.dart';
import '../models/cotizacion.dart';
import 'api_client.dart';

/// Servicio del flujo de ventas (cotización).
class VentasService {
  final ApiClient _api = ApiClient.instance;
  static const _base = '${ApiConfig.baseUrl}/api/ventas';

  // ---- Asesor ----
  Future<List<Cotizacion>> listarTodas() async {
    final data = await _api.get('$_base/cotizaciones/todas') as List;
    return data.map((e) => Cotizacion.fromJson(e)).toList();
  }

  Future<void> generar({
    required int clienteId,
    required int vehiculoId,
    required String fechaInicio,
    required String fechaFin,
  }) =>
      _api.post('$_base/cotizaciones', {
        'cliente_id': clienteId,
        'vehiculo_id': vehiculoId,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
      });

  Future<void> solicitarGarantia(int id) => _api.post('$_base/cotizaciones/$id/solicitar-garantia');
  Future<void> generarReserva(int id) => _api.post('$_base/cotizaciones/$id/generar-reserva');

  // ---- Cliente ----
  Future<List<Cotizacion>> mias() async {
    final data = await _api.get('$_base/cotizaciones/mias') as List;
    return data.map((e) => Cotizacion.fromJson(e)).toList();
  }

  Future<void> decidir(int id, bool aceptar) =>
      _api.patch('$_base/cotizaciones/$id/decidir', {'aceptar': aceptar});
  Future<void> pagarGarantia(int id, {String metodo = 'TARJETA'}) =>
      _api.patch('$_base/cotizaciones/$id/pagar-garantia', {'metodo': metodo});
}
