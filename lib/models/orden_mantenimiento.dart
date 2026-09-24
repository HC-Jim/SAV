/// Orden de mantenimiento — registro y consulta ("Buscar Orden").
class OrdenMantenimiento {
  final int id;
  final int? vehiculoId;
  final int? mecanicoId;
  final int? tipoMantenimientoId;
  final String? estado;
  final String? indicaciones;
  final String? fechaCreacion;
  final Map<String, dynamic>? vehiculo;
  final Map<String, dynamic>? tipoMantenimiento;
  final Map<String, dynamic>? mecanico;

  OrdenMantenimiento.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        vehiculoId = j['vehiculo_id'] as int?,
        mecanicoId = j['mecanico_id'] as int?,
        tipoMantenimientoId = j['tipo_mantenimiento_id'] as int?,
        estado = j['estado'] as String?,
        indicaciones = j['indicaciones'] as String?,
        fechaCreacion = j['fecha_creacion'] as String?,
        vehiculo = j['vehiculo'] as Map<String, dynamic>?,
        tipoMantenimiento = j['tipo_mantenimiento'] as Map<String, dynamic>?,
        mecanico = j['mecanico'] as Map<String, dynamic>?;

  String get vehiculoDesc {
    final v = vehiculo;
    if (v == null) return 'Vehículo $vehiculoId';
    return '${v['placa'] ?? ''} · ${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();
  }

  String get tipoNombre => (tipoMantenimiento?['nombre'] as String?) ?? '-';
  String get mecanicoNombre => (mecanico?['nombre'] as String?) ?? '-';

  String get estadoLegible {
    switch (estado) {
      case 'PENDIENTE_INSPECCION':
        return 'Pendiente de inspección';
      case 'CERRADO':
        return 'Cerrado';
      default:
        return estado ?? '-';
    }
  }
}
