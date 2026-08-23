import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Controlador de sesion (patron ChangeNotifier + provider).
/// Mantiene el usuario autenticado y expone login/logout a las vistas.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Usuario? _usuario;
  bool _cargando = false;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _authService.login(email.trim(), password);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo conectar con el servidor. Verifica la URL de la API.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void logout() {
    _authService.logout();
    _usuario = null;
    notifyListeners();
  }
}
