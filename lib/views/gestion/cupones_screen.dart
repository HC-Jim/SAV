import 'package:flutter/material.dart';
import '../../services/gestion_service.dart';

/// Cupones — tabla de cupones de descuento y su estado (disponible / usado).
class CuponesScreen extends StatefulWidget {
  const CuponesScreen({super.key});
  @override
  State<CuponesScreen> createState() => _CuponesScreenState();
}

class _CuponesScreenState extends State<CuponesScreen> {
  final _svc = GestionService();
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarCupones());

  String _valor(Map<String, dynamic> c) => c['tipo'] == 'PORCENTAJE'
      ? '${c['valor']}%'
      : 'S/ ${(c['valor'] as num).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupones'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final cupones = snap.data ?? [];
          if (cupones.isEmpty) {
            return const Center(child: Text('No hay cupones registrados.'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: cupones.map(_card).toList(),
          );
        },
      ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final usado = c['usado'] == true;
    final activo = c['activo'] == true;
    final String estado = usado
        ? 'Usado'
        : (activo ? 'Disponible' : 'Inactivo');
    final Color color = usado
        ? Colors.orange.shade800
        : (activo ? Colors.green.shade700 : Colors.black54);
    return Card(
      child: ListTile(
        leading: Icon(usado ? Icons.check_circle_outline : Icons.local_offer_outlined,
            color: color),
        title: Text('${c['codigo']}  ·  ${_valor(c)}'),
        subtitle: Text('${c['descripcion'] ?? ''}\n'
            'Tipo: ${c['tipo'] == 'PORCENTAJE' ? 'Porcentaje' : 'Monto'}'
            '${c['fecha_uso'] != null ? '  ·  Usado: ${c['fecha_uso'].toString().substring(0, 10)}' : ''}'),
        isThreeLine: true,
        trailing: Chip(
          label: Text(estado, style: TextStyle(color: color, fontSize: 12)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
