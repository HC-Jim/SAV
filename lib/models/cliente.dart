/// Cliente (para administración por el Jefe).
class Cliente {
  final int id;
  final String? tipoDocumento;
  final String numeroDocumento;
  final String? razonSocial;
  final String? licenciaConducir;
  final String? telefono;
  final String? correo;

  Cliente.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        tipoDocumento = j['tipo_documento'],
        numeroDocumento = j['numero_documento'] ?? '',
        razonSocial = j['razon_social'],
        licenciaConducir = j['licencia_conducir'],
        telefono = j['telefono'],
        correo = j['correo'];
}
