import 'mano_obra.dart';
import 'vehiculo.dart';

/// Estados de la Orden de Mantenimiento (deben coincidir con el backend).
class EstadoOrden {
  static const pendienteInspeccion = 'PENDIENTE_INSPECCION';
  static const inspeccionCompleta = 'INSPECCION_COMPLETA';
  static const inspeccionPostergada = 'INSPECCION_POSTERGADA';
  static const pendienteAutorizacion = 'PENDIENTE_AUTORIZACION_PRESUPUESTO';
  static const presupuestoAutorizado = 'PRESUPUESTO_AUTORIZADO';
  static const cerradaPorRechazo = 'CERRADA_POR_RECHAZO';
  static const enMantenimiento = 'EN_MANTENIMIENTO';
  static const pendienteConformidad = 'PENDIENTE_CONFORMIDAD';
  static const correccionRequerida = 'CORRECCION_REQUERIDA';
  static const cerrado = 'CERRADO';

  static const finales = [cerrado, cerradaPorRechazo];

  /// Texto legible para mostrar en la UI.
  static String legible(String estado) {
    switch (estado) {
      case pendienteInspeccion:
        return 'Pendiente de inspección';
      case inspeccionCompleta:
        return 'Inspección completa';
      case inspeccionPostergada:
        return 'Inspección postergada';
      case pendienteAutorizacion:
        return 'Pendiente de autorización';
      case presupuestoAutorizado:
        return 'Presupuesto autorizado';
      case cerradaPorRechazo:
        return 'Cerrada por rechazo';
      case enMantenimiento:
        return 'En mantenimiento';
      case pendienteConformidad:
        return 'Pendiente de conformidad';
      case correccionRequerida:
        return 'Corrección requerida';
      case cerrado:
        return 'Cerrado';
      default:
        return estado;
    }
  }
}

class Inspeccion {
  final int id;
  final String? diagnostico;
  final String? resultado;
  final bool necesitaRepuestos;
  final int? kilometrajeLectura;
  final String? nivelCombustible;
  final String? observaciones;

  Inspeccion.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        diagnostico = j['diagnostico'],
        resultado = j['resultado'],
        necesitaRepuestos = j['necesita_repuestos'] ?? false,
        kilometrajeLectura = j['kilometraje_lectura'],
        nivelCombustible = j['nivel_combustible'],
        observaciones = j['observaciones'];
}

class RepuestoItem {
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  RepuestoItem.fromJson(Map<String, dynamic> j)
      : nombre = j['nombre'] ?? 'Item',
        cantidad = j['cantidad'] ?? 1,
        precioUnitario = (j['precio_unitario'] as num?)?.toDouble() ?? 0;
}

class Requerimiento {
  final int id;
  final String estado; // SOLICITADO | COMPRADO
  final List<RepuestoItem> items;
  Requerimiento.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        estado = j['estado'] ?? 'SOLICITADO',
        items = ((j['repuesto_item'] as List?) ?? [])
            .map((e) => RepuestoItem.fromJson(e))
            .toList();
}

class Presupuesto {
  final int id;
  final double costoRepuestos;
  final double costoManoObra;
  final double total;
  final String estado; // PENDIENTE | AUTORIZADO | RECHAZADO
  final String? motivoRechazo;
  Presupuesto.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        costoRepuestos = (j['costo_repuestos'] as num?)?.toDouble() ?? 0,
        costoManoObra = (j['costo_mano_obra'] as num?)?.toDouble() ?? 0,
        total = (j['total'] as num?)?.toDouble() ?? 0,
        estado = j['estado'] ?? 'PENDIENTE',
        motivoRechazo = j['motivo_rechazo'];
}

class InformeTecnico {
  final int id;
  final String? trabajosRealizados;
  final String? resultadosPruebas;
  final bool? conforme;
  final String? motivoCorreccion;
  InformeTecnico.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        trabajosRealizados = j['trabajos_realizados'],
        resultadosPruebas = j['resultados_pruebas'],
        conforme = j['conforme'],
        motivoCorreccion = j['motivo_correccion'];
}

/// Orden de Mantenimiento. Sirve tanto para el listado (campos básicos)
/// como para el detalle (con documentos anidados).
class OrdenMantenimiento {
  final int id;
  final int vehiculoId;
  final int? mecanicoId;
  final String? tipoServicio;
  final String? descripcion;
  final String estado;
  final String? horaInicioMant;
  final String? horaFinMant;
  final String? observacionEjecucion;
  final int? duracionMinutos;
  final String? fechaCreacion;
  final Vehiculo? vehiculo;

  final List<Inspeccion> inspecciones;
  final List<Requerimiento> requerimientos;
  final List<ManoObra> manosObra;
  final List<Presupuesto> presupuestos;
  final List<InformeTecnico> informes;
  final Map<String, dynamic>? actaEntrega;

  OrdenMantenimiento.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        vehiculoId = j['vehiculo_id'],
        mecanicoId = j['mecanico_id'],
        tipoServicio = j['tipo_servicio'],
        descripcion = j['descripcion'],
        estado = j['estado'],
        horaInicioMant = j['hora_inicio_mant'],
        horaFinMant = j['hora_fin_mant'],
        observacionEjecucion = j['observacion_ejecucion'],
        duracionMinutos = j['duracion_minutos'],
        fechaCreacion = j['fecha_creacion'],
        vehiculo = j['vehiculo'] != null ? Vehiculo.fromJson(j['vehiculo']) : null,
        inspecciones = ((j['inspeccion'] as List?) ?? [])
            .map((e) => Inspeccion.fromJson(e))
            .toList(),
        requerimientos = ((j['requerimiento_repuesto'] as List?) ?? [])
            .map((e) => Requerimiento.fromJson(e))
            .toList(),
        manosObra = ((j['mano_obra'] as List?) ?? [])
            .map((e) => ManoObra.fromJson(e))
            .toList(),
        presupuestos = ((j['presupuesto'] as List?) ?? [])
            .map((e) => Presupuesto.fromJson(e))
            .toList(),
        informes = ((j['informe_tecnico'] as List?) ?? [])
            .map((e) => InformeTecnico.fromJson(e))
            .toList(),
        actaEntrega = j['acta_entrega'] as Map<String, dynamic>?;

  bool get esFinal => EstadoOrden.finales.contains(estado);

  /// Presupuesto pendiente de decisión (si existe).
  Presupuesto? get presupuestoPendiente =>
      presupuestos.where((p) => p.estado == 'PENDIENTE').isNotEmpty
          ? presupuestos.firstWhere((p) => p.estado == 'PENDIENTE')
          : (presupuestos.isNotEmpty ? presupuestos.last : null);

  /// El Mecánico registra requerimiento y mano de obra; el Jefe aprueba el
  /// presupuesto final (ya no hay aprobación por partes).
  bool get tieneRequerimiento => requerimientos.isNotEmpty;

  bool get tieneManoObra => manosObra.isNotEmpty;

  ManoObra? get manoObra => manosObra.isNotEmpty ? manosObra.first : null;
}
