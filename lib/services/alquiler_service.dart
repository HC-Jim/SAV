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

  /// 2. Registrar Pago de Orden de Reserva (Cliente): garantía + alquiler → RESERVADO
  /// (emite el comprobante como parte del pago).
  Future<void> pagarOrdenReserva(int reservaId, {String metodo = 'TARJETA'}) =>
      _api.patch('$_base/reservas/$reservaId/pagar', {'metodo': metodo});
}
