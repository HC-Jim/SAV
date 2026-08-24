import '../config/api_config.dart';
import '../models/cliente.dart';
import '../models/seguro.dart';
import '../models/vehiculo.dart';
import 'api_client.dart';

/// Servicio de administración interna (Jefe): CRUD de vehículos, clientes y seguros.
class GestionService {
  final ApiClient _api = ApiClient.instance;
  static const _base = '${ApiConfig.baseUrl}/api/gestion';

  // ---- Vehículos ----
  Future<List<Vehiculo>> listarVehiculos() async {
    final data = await _api.get('$_base/vehiculos') as List;
    return data.map((e) => Vehiculo.fromJson(e)).toList();
  }

  Future<void> crearVehiculo(Map<String, dynamic> datos) => _api.post('$_base/vehiculos', datos);
  Future<void> actualizarVehiculo(int id, Map<String, dynamic> datos) =>
      _api.patch('$_base/vehiculos/$id', datos);
  Future<void> eliminarVehiculo(int id) => _api.delete('$_base/vehiculos/$id');

  // ---- Clientes ----
  Future<List<Cliente>> listarClientes() async {
    final data = await _api.get('$_base/clientes') as List;
    return data.map((e) => Cliente.fromJson(e)).toList();
  }

  Future<void> crearCliente(Map<String, dynamic> datos) => _api.post('$_base/clientes', datos);
  Future<void> actualizarCliente(int id, Map<String, dynamic> datos) =>
      _api.patch('$_base/clientes/$id', datos);
  Future<void> eliminarCliente(int id) => _api.delete('$_base/clientes/$id');

  // ---- Seguros ----
  Future<List<Seguro>> listarSeguros() async {
    final data = await _api.get('$_base/seguros') as List;
    return data.map((e) => Seguro.fromJson(e)).toList();
  }

  Future<List<Seguro>> segurosPorVencer({int dias = 30}) async {
    final data = await _api.get('$_base/seguros/por-vencer?dias=$dias') as List;
    return data.map((e) => Seguro.fromJson(e)).toList();
  }

  Future<void> crearSeguro(Map<String, dynamic> datos) => _api.post('$_base/seguros', datos);
}
