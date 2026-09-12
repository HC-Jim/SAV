import '../config/api_config.dart';
import '../models/orden_mantenimiento.dart';
import '../models/repuesto.dart';
import '../models/tipo_mantenimiento.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import 'api_client.dart';

/// Servicio que consume los endpoints del proceso de mantenimiento.
class MantenimientoService {
  final ApiClient _api = ApiClient.instance;
  static const _base = ApiConfig.apiMantenimiento;

  // ---------- Consultas ----------
  Future<List<OrdenMantenimiento>> listarOrdenes({String? estado}) async {
    final url = estado == null || estado.isEmpty
        ? '$_base/ordenes'
        : '$_base/ordenes?estado=$estado';
    final data = await _api.get(url) as List;
    return data.map((e) => OrdenMantenimiento.fromJson(e)).toList();
  }

  Future<OrdenMantenimiento> obtenerOrden(int id) async {
    final data = await _api.get('$_base/ordenes/$id');
    return OrdenMantenimiento.fromJson(data);
  }

  Future<List<Vehiculo>> vehiculosPorMantener() async {
    final data = await _api.get('$_base/vehiculos/por-mantener') as List;
    return data.map((e) => Vehiculo.fromJson(e)).toList();
  }

  Future<List<Repuesto>> catalogoRepuestos() async {
    final data = await _api.get('$_base/repuestos') as List;
    return data.map((e) => Repuesto.fromJson(e)).toList();
  }

  Future<List<TipoMantenimiento>> tiposMantenimiento() async {
    final data = await _api.get('$_base/tipos-mantenimiento') as List;
    return data.map((e) => TipoMantenimiento.fromJson(e)).toList();
  }

  /// Comprar más stock de un repuesto del catálogo (Jefe de Logística).
  Future<void> comprarRepuesto(int repuestoId, int cantidad) =>
      _api.patch('$_base/repuestos/$repuestoId/comprar', {'cantidad': cantidad});

  Future<List<Usuario>> listarMecanicos() async {
    final data = await _api.get('$_base/mecanicos') as List;
    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  // ---------- Jefe de Logistica ----------
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

  // ---------- Mano de obra ----------
  Future<void> registrarManoObra(int ordenId,
          {required double costo, String? observacion}) =>
      _api.post('$_base/ordenes/$ordenId/mano-obra',
          {'costo': costo, 'observacion': observacion});

  Future<void> decidirConformidad(int ordenId, bool conforme, {String? motivo}) =>
      _api.patch('$_base/ordenes/$ordenId/conformidad',
          {'conforme': conforme, 'motivo': motivo});

  // ---------- Mecanico ----------
  Future<void> registrarInspeccion(int ordenId, Map<String, dynamic> datos) =>
      _api.post('$_base/ordenes/$ordenId/inspeccion', datos);

  /// Inspección + requerimiento + mano de obra + presupuesto en un solo paso.
  Future<void> procesarInspeccion(int ordenId, Map<String, dynamic> datos) =>
      _api.post('$_base/ordenes/$ordenId/inspeccion-completa', datos);

  Future<void> crearRequerimiento(int ordenId, List<Map<String, dynamic>> items) =>
      _api.post('$_base/ordenes/$ordenId/requerimientos', {'items': items});

  Future<void> generarPresupuesto(int ordenId, Map<String, dynamic> datos) =>
      _api.post('$_base/ordenes/$ordenId/presupuesto', datos);

  Future<void> iniciarMantenimiento(int ordenId) =>
      _api.patch('$_base/ordenes/$ordenId/iniciar');

  Future<void> finalizarMantenimiento(int ordenId, {String? observacion}) =>
      _api.patch('$_base/ordenes/$ordenId/finalizar', {'observacion': observacion});

  Future<void> generarInforme(int ordenId, Map<String, dynamic> datos) =>
      _api.post('$_base/ordenes/$ordenId/informe', datos);
}
