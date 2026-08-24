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

  /// Todas las reservas (gestión interna: Jefe, Cajero, Asesor).
  Future<List<Reserva>> listarTodas() async {
    final data = await _api.get('$_base/reservas/todas') as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> verReserva(int id) async {
    final data = await _api.get('$_base/reservas/$id');
    return Reserva.fromJson(data);
  }

  Future<void> pagarAlquiler(int reservaId, {String metodo = 'TARJETA'}) =>
      _api.patch('$_base/reservas/$reservaId/pagar-alquiler', {'metodo': metodo});

  Future<void> cancelar(int reservaId, {String? motivo}) =>
      _api.patch('$_base/reservas/$reservaId/cancelar', {'motivo': motivo});
}
