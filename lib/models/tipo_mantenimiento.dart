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
}
