/// Orden de mantenimiento — respuesta de "Registrar Orden de Mantenimiento".
///
/// El alcance vigente solo registra la orden (no hay inspección, presupuesto,
/// ejecución ni conformidad), por lo que el modelo es mínimo.
class OrdenMantenimiento {
  final int id;
  final int? vehiculoId;
  final int? mecanicoId;
  final int? tipoMantenimientoId;
  final String? estado;
  final String? indicaciones;

  OrdenMantenimiento.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        vehiculoId = j['vehiculo_id'] as int?,
        mecanicoId = j['mecanico_id'] as int?,
        tipoMantenimientoId = j['tipo_mantenimiento_id'] as int?,
        estado = j['estado'] as String?,
        indicaciones = j['indicaciones'] as String?;
}
