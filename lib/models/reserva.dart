import 'vehiculo.dart';

/// Estados de la reserva (coinciden con el backend).
class EstadoReserva {
  static const pendienteAprobacion = 'PENDIENTE_APROBACION';
  static const pendientePago = 'PENDIENTE_PAGO_GARANTIA';
  static const confirmada = 'CONFIRMADA';
  static const enCurso = 'EN_CURSO';
  static const finalizada = 'FINALIZADA';
  static const cancelada = 'CANCELADA';

  static String legible(String e) {
    switch (e) {
      case pendienteAprobacion:
        return 'Pendiente de aprobación (Cajero)';
      case pendientePago:
        return 'Pendiente de pago de garantía';
      case confirmada:
        return 'Confirmada';
      case enCurso:
        return 'En curso';
      case finalizada:
        return 'Finalizada';
      case cancelada:
        return 'Cancelada';
      default:
        return e;
    }
  }
}

class Reserva {
  final int id;
  final int? vehiculoId;
  final String? fechaInicio;
  final String? fechaFin;
  final String estado;
  final double montoTotalEstimado;
  final double garantiaMonto;
  final double penalidad;
  final double montoDevuelto;
  final String? motivoCancelacion;
  final Vehiculo? vehiculo;

  Reserva.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        vehiculoId = j['vehiculo_id'],
        fechaInicio = j['fecha_inicio'],
        fechaFin = j['fecha_fin'],
        estado = j['estado'],
        montoTotalEstimado = (j['monto_total_estimado'] as num?)?.toDouble() ?? 0,
        garantiaMonto = (j['garantia_monto'] as num?)?.toDouble() ?? 0,
        penalidad = (j['penalidad'] as num?)?.toDouble() ?? 0,
        montoDevuelto = (j['monto_devuelto'] as num?)?.toDouble() ?? 0,
        motivoCancelacion = j['motivo_cancelacion'],
        vehiculo = j['vehiculo'] != null ? Vehiculo.fromJson(j['vehiculo']) : null;

  bool get esFinal =>
      estado == EstadoReserva.finalizada || estado == EstadoReserva.cancelada;
}
