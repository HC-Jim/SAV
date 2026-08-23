/// Configuracion de la API del backend.
///
/// - En desarrollo local: http://localhost:3000
/// - En produccion (Render): reemplaza por https://tu-servicio.onrender.com
///
/// Nota: si corres la app en un emulador Android, usa http://10.0.2.2:3000
/// (10.0.2.2 es el "localhost" de la maquina anfitriona desde el emulador).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String apiAuth = '$baseUrl/api/auth';
  static const String apiMantenimiento = '$baseUrl/api/mantenimiento';
}
