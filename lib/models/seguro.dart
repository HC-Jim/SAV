/// Póliza de seguro (para administración por el Jefe).
class Seguro {
  final int id;
  final int vehiculoId;
  final String? tipoSeguro;
  final String? numPoliza;
  final String? aseguradoraEntidad;
  final String? fechaEmision;
  final String? fechaVencimiento;
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
        diasParaVencer = j['dias_para_vencer'],
        vehiculo = j['vehiculo'] as Map<String, dynamic>?;

  String get vehiculoDesc => vehiculo != null
      ? '${vehiculo!['marca'] ?? ''} ${vehiculo!['modelo'] ?? ''} (${vehiculo!['placa'] ?? ''})'.trim()
      : 'Vehículo $vehiculoId';
}
