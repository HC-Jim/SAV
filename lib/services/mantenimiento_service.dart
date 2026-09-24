import '../config/api_config.dart';
import '../models/orden_mantenimiento.dart';
import '../models/tipo_mantenimiento.dart';
import '../models/usuario.dart';
import 'api_client.dart';

/// Servicio del proceso de mantenimiento.
/// Alcance vigente: solo "Registrar Orden de Mantenimiento" (Jefe de Logística),
/// que «incluye» Buscar Mecánico y usa el catálogo de tipos de mantenimiento.
class MantenimientoService {
  final ApiClient _api = ApiClient.instance;
  static const _base = ApiConfig.apiMantenimiento;

  Future<List<TipoMantenimiento>> tiposMantenimiento() async {
    final data = await _api.get('$_base/tipos-mantenimiento') as List;
    return data.map((e) => TipoMantenimiento.fromJson(e)).toList();
  }

  // «include» Buscar Mecánico
  Future<List<Usuario>> listarMecanicos() async {
    final data = await _api.get('$_base/mecanicos') as List;
    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  // Registrar Orden de Mantenimiento (Jefe de Logística)
  Future<OrdenMantenimiento> crearOrden({
    required int vehiculoId,
    required int mecanicoId,
    required int tipoMantenimientoId,
    String? indicaciones,
  }) async {
    final data = await _api.post('$_base/ordenes', {
      'vehiculo_id': vehiculoId,
      'mecanico_id': mecanicoId,
      'tipo_mantenimiento_id': tipoMantenimientoId,
      'indicaciones': indicaciones,
    });
    return OrdenMantenimiento.fromJson(data as Map<String, dynamic>);
  }
}
