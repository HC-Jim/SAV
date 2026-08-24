import 'package:flutter/material.dart';
import '../../models/seguro.dart';
import '../../models/vehiculo.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Registrar Pólizas / Seguros + alerta de vencimiento (CUS017 / CUS018).
class SegurosScreen extends StatefulWidget {
  const SegurosScreen({super.key});
  @override
  State<SegurosScreen> createState() => _SegurosScreenState();
}

class _SegurosScreenState extends State<SegurosScreen> {
  final _svc = GestionService();
  late Future<List<Seguro>> _futuro;
  bool _soloPorVencer = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro =
      _soloPorVencer ? _svc.segurosPorVencer(dias: 30) : _svc.listarSeguros());

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguros y pólizas'),
        actions: [
          Row(children: [
            const Text('Por vencer'),
            Switch(
              value: _soloPorVencer,
              onChanged: (v) {
                _soloPorVencer = v;
                _cargar();
              },
            ),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirForm,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Seguro>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final lista = snap.data ?? [];
          if (lista.isEmpty) return const Center(child: Text('Sin pólizas registradas.'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: lista.map(_card).toList(),
          );
        },
      ),
    );
  }

  Widget _card(Seguro s) {
    final dias = s.diasParaVencer;
    final vencido = dias != null && dias < 0;
    final proximo = dias != null && dias >= 0 && dias <= 30;
    String etiqueta;
    if (vencido) {
      etiqueta = 'Vencida hace ${-dias} días';
    } else if (proximo) {
      etiqueta = 'Vence en $dias días';
    } else {
      etiqueta = dias != null ? 'Vence en $dias días' : 'Sin fecha';
    }
    final color = vencido ? Colors.black : Colors.black54;
    return Card(
      child: ListTile(
        leading: Icon(Icons.shield_outlined, color: color),
        title: Text('${s.tipoSeguro ?? 'Seguro'}  ·  ${s.numPoliza ?? ''}'),
        subtitle: Text('${s.vehiculoDesc}\n${s.aseguradoraEntidad ?? ''}  ·  vence: ${s.fechaVencimiento ?? '-'}\n'
            '$etiqueta'),
        isThreeLine: true,
        trailing: TextButton.icon(
          icon: const Icon(Icons.autorenew),
          label: const Text('Renovar'),
          onPressed: () => _renovar(s),
        ),
      ),
    );
  }

  Future<void> _renovar(Seguro s) async {
    final poliza = TextEditingController(text: s.numPoliza ?? '');
    final emision = TextEditingController();
    final vencimiento = TextEditingController();

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Renovar póliza (${s.vehiculoDesc})'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(poliza, 'N° de póliza (nueva)'),
            _campo(emision, 'Fecha emisión (YYYY-MM-DD)'),
            _campo(vencimiento, 'Fecha vencimiento (YYYY-MM-DD)'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'num_poliza': poliza.text.trim(),
              'fecha_emision': emision.text.trim(),
              'fecha_vencimiento': vencimiento.text.trim(),
            }),
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
    if (datos != null) {
      try {
        await _svc.renovarSeguro(s.id, datos);
        if (mounted) _cargar();
      } on ApiException catch (e) {
        _snack(e.mensaje);
      }
    }
  }

  Future<void> _abrirForm() async {
    List<Vehiculo> vehiculos = [];
    try {
      vehiculos = await _svc.listarVehiculos();
    } on ApiException catch (e) {
      _snack(e.mensaje);
      return;
    }
    if (!mounted) return;

    int? vehiculoId = vehiculos.isNotEmpty ? vehiculos.first.id : null;
    final tipo = TextEditingController(text: 'SOAT');
    final poliza = TextEditingController();
    final aseguradora = TextEditingController();
    final emision = TextEditingController();
    final vencimiento = TextEditingController();

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nueva póliza'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: vehiculoId,
                decoration: const InputDecoration(labelText: 'Vehículo'),
                items: vehiculos
                    .map((v) => DropdownMenuItem(value: v.id, child: Text('${v.placa} ${v.marca ?? ''}')))
                    .toList(),
                onChanged: (v) => setLocal(() => vehiculoId = v),
              ),
              _campo(tipo, 'Tipo (SOAT / TODO_RIESGO)'),
              _campo(poliza, 'N° de póliza'),
              _campo(aseguradora, 'Aseguradora'),
              _campo(emision, 'Fecha emisión (YYYY-MM-DD)'),
              _campo(vencimiento, 'Fecha vencimiento (YYYY-MM-DD)'),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'vehiculo_id': vehiculoId,
                'tipo_seguro': tipo.text.trim(),
                'num_poliza': poliza.text.trim(),
                'aseguradora_entidad': aseguradora.text.trim(),
                'fecha_emision': emision.text.trim().isEmpty ? null : emision.text.trim(),
                'fecha_vencimiento': vencimiento.text.trim().isEmpty ? null : vencimiento.text.trim(),
              }),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (datos != null && datos['vehiculo_id'] != null) {
      try {
        await _svc.crearSeguro(datos);
        if (mounted) _cargar();
      } on ApiException catch (e) {
        _snack(e.mensaje);
      }
    }
  }

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: c, decoration: InputDecoration(labelText: label)),
      );
}
