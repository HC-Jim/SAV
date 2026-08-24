/// Entrada del catálogo de precios (tarifa por categoría).
class CatalogoPrecio {
  final int id;
  final String categoria;
  final String? descripcion;
  final double precioDia;
  final bool vigente;

  CatalogoPrecio.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        categoria = j['categoria'] ?? '',
        descripcion = j['descripcion'],
        precioDia = (j['precio_dia'] as num?)?.toDouble() ?? 0,
        vigente = j['vigente'] ?? true;
}
