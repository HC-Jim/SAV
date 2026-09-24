/// Vehículo de la flota.
///
/// Modelo de precios simplificado: cada auto tiene un **precio de alquiler
/// fijo** (por el periodo por defecto) y un **costo de garantía fijo**, ambos
/// editables por el Administrador en "Catálogo de precios".
class Vehiculo {
  final int id;
  final String? sku;
  final String placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? color;
  final String? categoria;
  final double precioAlquiler; // precio fijo total del alquiler
  final double garantia;       // costo de garantía fijo (depósito)
  final int? kilometraje;
  final String? fechaProximoMantenimiento;
  final String? estado;

  /// Días de alquiler por defecto.
  static const int diasPorDefecto = 3;

  Vehiculo({
    required this.id,
    this.sku,
    required this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.color,
    this.categoria,
    this.precioAlquiler = 0,
    this.garantia = 0,
    this.kilometraje,
    this.fechaProximoMantenimiento,
    this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: (json['id'] as int?) ?? 0,
        sku: json['sku'] as String?,
        placa: (json['placa'] as String?) ?? '',
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        anio: json['anio'] as int?,
        color: json['color'] as String?,
        categoria: json['categoria'] as String?,
        precioAlquiler: (json['precio_normal'] as num?)?.toDouble() ?? 0,
        garantia: (json['garantia'] as num?)?.toDouble() ?? 0,
        kilometraje: json['kilometraje'] as int?,
        fechaProximoMantenimiento: json['fecha_proximo_mantenimiento'] as String?,
        estado: json['estado'] as String?,
      );

  String get estadoLegible {
    switch (estado) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'ALQUILADO':
        return 'Alquilado';
      case 'EN_MANTENIMIENTO':
        return 'En mantenimiento';
      default:
        return estado ?? '-';
    }
  }

  String get descripcion => '$placa · ${marca ?? ''} ${modelo ?? ''}'.trim();
}
