/// Póliza de seguro (para administración por el Jefe).
class Seguro {
  final int id;
  final int vehiculoId;
  final String? tipoSeguro;
  final String? numPoliza;
  final String? aseguradoraEntidad;
  final String? fechaEmision;
  final String? fechaVencimiento;
  final double? sumaAsegurada;
  final double? prima;
  final double? deducible;
  final String? frecuenciaPago;
  final String? moneda;
  final String? contactoAseguradora;
  final String? cobertura;
  final String? observaciones;
  final int? diasParaVencer;
  final Map<String, dynamic>? vehiculo;

  Seguro.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        vehiculoId = j['vehiculo_id'],
        tipoSeguro = j['tipo_seguro'],
        numPoliza = j['num_poliza'],
        aseguradoraEntidad = j['aseguradora_entidad'],
        fechaEmision = j['fecha_emision'],
        fechaVencimiento = j['fecha_vencimiento'],
        sumaAsegurada = (j['suma_asegurada'] as num?)?.toDouble(),
        prima = (j['prima'] as num?)?.toDouble(),
        deducible = (j['deducible'] as num?)?.toDouble(),
        frecuenciaPago = j['frecuencia_pago'],
        moneda = j['moneda'],
        contactoAseguradora = j['contacto_aseguradora'],
        cobertura = j['cobertura'],
        observaciones = j['observaciones'],
        diasParaVencer = j['dias_para_vencer'],
        vehiculo = j['vehiculo'] as Map<String, dynamic>?;

  String get vehiculoDesc => vehiculo != null
      ? '${vehiculo!['marca'] ?? ''} ${vehiculo!['modelo'] ?? ''} (${vehiculo!['placa'] ?? ''})'.trim()
      : 'Vehículo $vehiculoId';
}
