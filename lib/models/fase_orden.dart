/// Fase del proceso de mantenimiento, para dividir el flujo en dos módulos:
/// - [presupuesto]: inspección → requerimiento → mano de obra → presupuesto
///   (el Jefe aprueba/rechaza) + documento Presupuesto (PDF).
/// - [informe]: ejecución → pruebas → informe técnico (el Jefe aprueba/rechaza
///   la conformidad y cierra) + documento Informe Técnico (PDF).
enum FaseOrden { presupuesto, informe }

/// Estados que pertenecen a la fase de Presupuesto.
const Set<String> estadosPresupuesto = {
  'PENDIENTE_INSPECCION',
  'INSPECCION_COMPLETA',
  'INSPECCION_POSTERGADA',
  'PENDIENTE_AUTORIZACION_PRESUPUESTO',
  'CERRADA_POR_RECHAZO',
};

/// Deduce la fase a partir del estado de la orden.
FaseOrden faseDeEstado(String estado) =>
    estadosPresupuesto.contains(estado) ? FaseOrden.presupuesto : FaseOrden.informe;
