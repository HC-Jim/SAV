import 'vehiculo.dart';

/// Estados de la orden de reserva (coinciden con el backend).
class EstadoReserva {
  static const porPagar = 'POR_PAGAR';
  static const reservado = 'RESERVADO';
  static const finalizada = 'FINALIZADA';

  static String legible(String e) {
    switch (e) {
      case porPagar:
        return 'Por pagar';
      case reservado:
        return 'Reservado';
      case finalizada:
        return 'Finalizada';
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

  bool get esFinal => estado == EstadoReserva.finalizada;
}
