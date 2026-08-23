/// Vehiculo de la flota.
class Vehiculo {
  final int id;
  final String placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final int? kilometraje;
  final String? fechaProximoMantenimiento;
  final String? estado;

  Vehiculo({
    required this.id,
    required this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.kilometraje,
    this.fechaProximoMantenimiento,
    this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['id'] as int,
        placa: json['placa'] as String,
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        anio: json['anio'] as int?,
        kilometraje: json['kilometraje'] as int?,
        fechaProximoMantenimiento: json['fecha_proximo_mantenimiento'] as String?,
        estado: json['estado'] as String?,
      );

  String get descripcion =>
      '$placa · ${marca ?? ''} ${modelo ?? ''}'.trim();
}
