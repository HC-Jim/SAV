/// Mano de obra de una orden (paso aparte del presupuesto, con aprobación).
class ManoObra {
  final int id;
  final double costo;
  final String? observacion;
  final String estado; // SOLICITADO | APROBADO

  ManoObra.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        costo = (j['costo'] as num?)?.toDouble() ?? 0,
        observacion = j['observacion'],
        estado = j['estado'] ?? 'SOLICITADO';
}
