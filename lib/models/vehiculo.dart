/// Vehiculo de la flota.
class Vehiculo {
  final int id;
  final String? sku;
  final String placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? color;
  final String? categoria;
  final double precioRegular;
  final double precioNormal;
  final double precioCampania;
  final int diasMinCampania;
  final int? kilometraje;
  final String? fechaProximoMantenimiento;
  final String? estado;

  Vehiculo({
    required this.id,
    this.sku,
    required this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.color,
    this.categoria,
    this.precioRegular = 0,
    this.precioNormal = 0,
    this.precioCampania = 0,
    this.diasMinCampania = 7,
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
        precioRegular: (json['precio_regular'] as num?)?.toDouble() ?? 0,
        precioNormal: (json['precio_normal'] as num?)?.toDouble() ?? 0,
        precioCampania: (json['precio_campania'] as num?)?.toDouble() ?? 0,
        diasMinCampania: json['dias_min_campania'] as int? ?? 7,
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

  String get descripcion =>
      '$placa · ${marca ?? ''} ${modelo ?? ''}'.trim();
}
