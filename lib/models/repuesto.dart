/// Repuesto del catalogo de almacen.
class Repuesto {
  final int id;
  final String nombre;
  final String? referencia;
  final double costoUnitario;
  final int stock;

  Repuesto({
    required this.id,
    required this.nombre,
    this.referencia,
    required this.costoUnitario,
    required this.stock,
  });

  factory Repuesto.fromJson(Map<String, dynamic> json) => Repuesto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        referencia: json['referencia'] as String?,
        costoUnitario: (json['costo_unitario'] as num).toDouble(),
        stock: json['stock'] as int,
      );
}
