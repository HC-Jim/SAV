import '../config/api_config.dart';
import '../models/reserva.dart';
import '../models/vehiculo.dart';
import 'api_client.dart';

/// Servicio del modulo de alquiler (Cliente).
class AlquilerService {
  final ApiClient _api = ApiClient.instance;
  static const _base = '${ApiConfig.baseUrl}/api/alquiler';

  // ---------- Catalogo ----------
  Future<List<Vehiculo>> catalogo({bool soloDisponibles = true}) async {
    final url = soloDisponibles ? '$_base/vehiculos' : '$_base/vehiculos?todos=true';
    final data = await _api.get(url) as List;
    return data.map((e) => Vehiculo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> disponibilidad(
      int vehiculoId, String fechaInicio, String fechaFin) async {
    final url = '$_base/disponibilidad?vehiculo_id=$vehiculoId'
        '&fecha_inicio=$fechaInicio&fecha_fin=$fechaFin';
    return await _api.get(url) as Map<String, dynamic>;
  }

  // ---------- Reservas ----------
  Future<List<Reserva>> misReservas() async {
    final data = await _api.get('$_base/reservas/mias') as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> verReserva(int id) async {
    final data = await _api.get('$_base/reservas/$id');
    return Reserva.fromJson(data);
  }

  /// 1. Generar Orden de Reserva (Cliente) → estado POR_PAGAR.
  Future<void> generarOrdenReserva({
    required int vehiculoId,
    required String fechaInicio,
    required String fechaFin,
  }) =>
      _api.post('$_base/reservas', {
        'vehiculo_id': vehiculoId,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
      });

  /// Aplicar Cupón: valida el código sobre el alquiler de la reserva.
  /// Devuelve {codigo, tipo, valor, descuento}.
  Future<Map<String, dynamic>> validarCupon(int reservaId, String codigo) async {
    final data = await _api.post('$_base/reservas/$reservaId/cupon', {'codigo': codigo});
    return Map<String, dynamic>.from(data as Map);
  }

  /// 2. Registrar Pago de Orden de Reserva (Cliente): garantía + alquiler → RESERVADO
  /// (emite el comprobante como parte del pago). Admite Tarjeta (crédito/débito,
  /// cuotas) o Yape, y un cupón de descuento.
  Future<Map<String, dynamic>> pagarOrdenReserva(
    int reservaId, {
    required String metodo, // TARJETA / YAPE
    String? tipoTarjeta, // CREDITO / DEBITO
    int? cuotas,
    String? tarjetaUltimos4,
    String? tarjetaMarca,
    String? yapeCelular,
    String? yapeOperacion,
    String? cuponCodigo,
  }) async {
    final body = <String, dynamic>{'metodo': metodo};
    if (tipoTarjeta != null) body['tipo_tarjeta'] = tipoTarjeta;
    if (cuotas != null) body['cuotas'] = cuotas;
    if (cuponCodigo != null && cuponCodigo.isNotEmpty) body['cupon_codigo'] = cuponCodigo;
    if (metodo == 'TARJETA') {
      body['tarjeta'] = {'ultimos4': tarjetaUltimos4, 'marca': tarjetaMarca};
    } else if (metodo == 'YAPE') {
      body['yape'] = {'celular': yapeCelular, 'operacion': yapeOperacion};
    }
    final data = await _api.patch('$_base/reservas/$reservaId/pagar', body);
    return Map<String, dynamic>.from(data as Map);
  }
}
