/// Precio por categoría (regular / normal / campaña por rango de días).
class CatalogoPrecio {
  final int id;
  final String categoria;
  final String? descripcion;
  final double precioRegular;
  final double precioNormal;
  final double precioCampania;
  final int diasMinCampania;
  final bool vigente;

  CatalogoPrecio.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        categoria = j['categoria'] ?? '',
        descripcion = j['descripcion'],
        precioRegular = (j['precio_regular'] as num?)?.toDouble() ?? 0,
        precioNormal = (j['precio_normal'] as num?)?.toDouble() ?? 0,
        precioCampania = (j['precio_campania'] as num?)?.toDouble() ?? 0,
        diasMinCampania = j['dias_min_campania'] ?? 7,
        vigente = j['vigente'] ?? true;
}
