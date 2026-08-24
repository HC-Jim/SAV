/// Vehiculo de la flota.
class Vehiculo {
  final int id;
  final String placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? color;
  final int? kilometraje;
  final double? tarifaDiaria;
  final String? fechaProximoMantenimiento;
  final String? estado;

  Vehiculo({
    required this.id,
    required this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.color,
    this.kilometraje,
    this.tarifaDiaria,
    this.fechaProximoMantenimiento,
    this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['id'] as int,
        placa: json['placa'] as String,
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        anio: json['anio'] as int?,
        color: json['color'] as String?,
        kilometraje: json['kilometraje'] as int?,
        tarifaDiaria: (json['tarifa_diaria'] as num?)?.toDouble(),
        fechaProximoMantenimiento: json['fecha_proximo_mantenimiento'] as String?,
        estado: json['estado'] as String?,
      );

  String get descripcion =>
      '$placa · ${marca ?? ''} ${modelo ?? ''}'.trim();
}
