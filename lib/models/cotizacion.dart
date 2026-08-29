import 'vehiculo.dart';

class EstadoCotizacion {
  static const pendiente = 'PENDIENTE';
  static const aceptada = 'ACEPTADA';
  static const rechazada = 'RECHAZADA';
  static const garantiaSolicitada = 'GARANTIA_SOLICITADA';
  static const garantiaPagada = 'GARANTIA_PAGADA';
  static const garantiaAprobada = 'GARANTIA_APROBADA';
  static const convertida = 'CONVERTIDA';

  static String legible(String e) {
    switch (e) {
      case pendiente:
        return 'Pendiente de decisión';
      case aceptada:
        return 'Aceptada';
      case rechazada:
        return 'Rechazada';
      case garantiaSolicitada:
        return 'Garantía solicitada';
      case garantiaPagada:
        return 'Garantía pagada (pendiente de aprobación)';
      case garantiaAprobada:
        return 'Garantía aprobada';
      case convertida:
        return 'Convertida en reserva';
      default:
        return e;
    }
  }
}

class Cotizacion {
  final int id;
  final int clienteId;
  final int vehiculoId;
  final String? fechaInicio;
  final String? fechaFin;
  final int dias;
  final double montoTotalEstimado;
  final double garantiaMonto;
  final String estado;
  final Vehiculo? vehiculo;
  final Map<String, dynamic>? cliente;

  Cotizacion.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        clienteId = j['cliente_id'],
        vehiculoId = j['vehiculo_id'],
        fechaInicio = j['fecha_inicio'],
        fechaFin = j['fecha_fin'],
        dias = j['dias'] ?? 1,
        montoTotalEstimado = (j['monto_total_estimado'] as num?)?.toDouble() ?? 0,
        garantiaMonto = (j['garantia_monto'] as num?)?.toDouble() ?? 0,
        estado = j['estado'],
        vehiculo = j['vehiculo'] != null ? Vehiculo.fromJson(j['vehiculo']) : null,
        cliente = j['cliente'] as Map<String, dynamic>?;

  String get vehiculoDesc => vehiculo != null
      ? '${vehiculo!.marca ?? ''} ${vehiculo!.modelo ?? ''} (${vehiculo!.placa})'.trim()
      : 'Vehículo $vehiculoId';
  String get clienteDesc => cliente?['razon_social']?.toString() ?? 'Cliente $clienteId';
}
