/// Fase del proceso de mantenimiento, para dividir el flujo en dos módulos:
/// - [presupuesto]: inspección → requerimiento → mano de obra → presupuesto
///   (el Jefe aprueba/rechaza) + documento Presupuesto (PDF).
/// - [informe]: ejecución → pruebas → informe técnico (el Jefe aprueba/rechaza)
///   + documento Informe Técnico (PDF).
enum FaseOrden { presupuesto, informe }
