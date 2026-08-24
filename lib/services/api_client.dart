import 'dart:convert';
import 'package:http/http.dart' as http;

/// Error de API con el mensaje devuelto por el backend.
class ApiException implements Exception {
  final String mensaje;
  final int? status;
  ApiException(this.mensaje, [this.status]);
  @override
  String toString() => mensaje;
}

/// Cliente HTTP central: inyecta el token JWT y traduce las respuestas.
/// Es un singleton para compartir el token entre servicios.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String url) async {
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _procesar(res);
  }

  Future<dynamic> post(String url, [Map<String, dynamic>? body]) async {
    final res = await http.post(Uri.parse(url),
        headers: _headers, body: jsonEncode(body ?? {}));
    return _procesar(res);
  }

  Future<dynamic> patch(String url, [Map<String, dynamic>? body]) async {
    final res = await http.patch(Uri.parse(url),
        headers: _headers, body: jsonEncode(body ?? {}));
    return _procesar(res);
  }

  Future<dynamic> delete(String url) async {
    final res = await http.delete(Uri.parse(url), headers: _headers);
    return _procesar(res);
  }

  dynamic _procesar(http.Response res) {
    final cuerpo = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return cuerpo;
    }
    final msg = (cuerpo is Map && cuerpo['error'] != null)
        ? cuerpo['error'].toString()
        : 'Error ${res.statusCode}';
    throw ApiException(msg, res.statusCode);
  }
}
