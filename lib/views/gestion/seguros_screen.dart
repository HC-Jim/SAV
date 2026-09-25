import 'package:flutter/material.dart';
import '../../models/seguro.dart';
import '../../services/gestion_service.dart';

/// Buscar Seguro — interfaz de consulta/búsqueda de pólizas registradas.
/// (El registro se hace en la interfaz "Registrar seguro".)
class SegurosScreen extends StatefulWidget {
  const SegurosScreen({super.key});
  @override
  State<SegurosScreen> createState() => _SegurosScreenState();
}

class _SegurosScreenState extends State<SegurosScreen> {
  final _svc = GestionService();
  late Future<List<Seguro>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarSeguros());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar seguro'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar póliza',
                hintText: 'Vehículo, tipo o N° de póliza…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Seguro>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                final todos = snap.data ?? [];
                final lista = _filtro.isEmpty
                    ? todos
                    : todos.where((s) => (
                          '${s.vehiculoDesc} ${s.tipoSeguro ?? ''} ${s.numPoliza ?? ''}')
                        .toLowerCase()
                        .contains(_filtro)).toList();
                if (lista.isEmpty) return const Center(child: Text('Sin pólizas.'));
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: lista.map(_card).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Seguro s) {
    final dias = s.diasParaVencer;
    final vencido = dias != null && dias < 0;
    String etiqueta;
    if (vencido) {
      etiqueta = 'Vencida hace ${-dias} días';
    } else {
      etiqueta = dias != null ? 'Vence en $dias días' : 'Sin fecha';
    }
    final montos = [
      if (s.sumaAsegurada != null) 'Suma: S/ ${s.sumaAsegurada!.toStringAsFixed(2)}',
      if (s.prima != null) 'Prima: S/ ${s.prima!.toStringAsFixed(2)}',
    ].join('  ·  ');
    return Card(
      child: ListTile(
        leading: Icon(Icons.shield_outlined, color: vencido ? Colors.black : Colors.black54),
        title: Text('${s.tipoSeguro ?? 'Seguro'}  ·  ${s.numPoliza ?? ''}'),
        subtitle: Text('${s.vehiculoDesc}\n${s.aseguradoraEntidad ?? ''}  ·  vence: ${s.fechaVencimiento ?? '-'}\n'
            '$etiqueta${montos.isNotEmpty ? '  ·  $montos' : ''}'
            '${s.cobertura != null ? '\nCobertura: ${s.cobertura}' : ''}'),
        isThreeLine: true,
      ),
    );
  }
}
