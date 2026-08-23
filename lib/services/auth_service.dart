import '../config/api_config.dart';
import '../models/usuario.dart';
import 'api_client.dart';

/// Servicio de autenticacion contra el backend.
class AuthService {
  final ApiClient _api = ApiClient.instance;

  /// Inicia sesion. Devuelve el usuario y deja el token en el ApiClient.
  Future<Usuario> login(String email, String password) async {
    final data = await _api.post('${ApiConfig.apiAuth}/login', {
      'email': email,
      'password': password,
    });
    _api.setToken(data['token'] as String);
    return Usuario.fromJson(data['usuario']);
  }

  void logout() => _api.setToken(null);
}
