/// Tipo de mantenimiento del catálogo (preventivo, correctivo, etc.).
class TipoMantenimiento {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final int? frecuenciaKm;
  final int? frecuenciaDias;
  final double? duracionEstimadaHoras;

  TipoMantenimiento.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        codigo = j['codigo'] ?? '',
        nombre = j['nombre'] ?? '',
        descripcion = j['descripcion'],
        categoria = j['categoria'],
        frecuenciaKm = j['frecuencia_km'],
        frecuenciaDias = j['frecuencia_dias'],
        duracionEstimadaHoras = (j['duracion_estimada_horas'] as num?)?.toDouble();

  /// Frecuencia legible: "cada 5.000 km / 180 días", "cada 90 días" o "por falla".
  String get frecuenciaTexto {
    final partes = <String>[];
    if (frecuenciaKm != null) partes.add('${_miles(frecuenciaKm!)} km');
    if (frecuenciaDias != null) partes.add('$frecuenciaDias días');
    if (partes.isEmpty) return 'por falla';
    return 'cada ${partes.join(' / ')}';
  }

  static String _miles(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
