import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/mantenimiento_service.dart';

/// «include» **Buscar Mecánico** — componente reutilizable en toda la app.
///
/// Muestra un campo con el mecánico elegido y, al tocarlo, abre el mismo
/// buscador (lista de mecánicos con jornada, especialidad, disponibilidad y
/// carga de trabajo). Al ser un único rendering, el caso incluido se ve igual
/// desde cualquier flujo (Crear Orden, reasignación, etc.).
class SelectorMecanico extends StatelessWidget {
  final Usuario? value;
  final ValueChanged<Usuario?> onChanged;

  /// Si es true, solo ofrece mecánicos marcados como disponibles.
  final bool soloDisponibles;
  final String label;

  const SelectorMecanico({
    super.key,
    required this.value,
    required this.onChanged,
    this.soloDisponibles = false,
    this.label = 'Mecánico',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegido = await Navigator.of(context).push<Usuario>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _BuscadorMecanicoScreen(soloDisponibles: soloDisponibles),
          ),
        );
        if (elegido != null) onChanged(elegido);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.engineering),
          suffixIcon: value == null
              ? const Icon(Icons.search)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null
              ? 'Buscar mecánico…'
              : '${value!.nombre}  ·  ${value!.especialidad ?? 'General'}',
          style: TextStyle(
            color: value == null ? Colors.black54 : Colors.black,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Buscador de mecánicos a pantalla completa (rendering único del caso
/// «include» Buscar Mecánico).
class _BuscadorMecanicoScreen extends StatefulWidget {
  final bool soloDisponibles;
  const _BuscadorMecanicoScreen({required this.soloDisponibles});

  @override
  State<_BuscadorMecanicoScreen> createState() => _BuscadorMecanicoScreenState();
}

class _BuscadorMecanicoScreenState extends State<_BuscadorMecanicoScreen> {
  final _svc = MantenimientoService();
  late Future<List<Usuario>> _futuro;
  String _filtro = '';
  late bool _soloDisponibles;

  @override
  void initState() {
    super.initState();
    _soloDisponibles = widget.soloDisponibles;
    _futuro = _svc.listarMecanicos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar mecánico')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nombre o especialidad…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Solo disponibles'),
              value: _soloDisponibles,
              onChanged: (v) => setState(() => _soloDisponibles = v),
            ),
            Expanded(
              child: FutureBuilder<List<Usuario>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('${snap.error}'));
                  var lista = snap.data ?? [];
                  if (_soloDisponibles) {
                    lista = lista.where((m) => m.disponible != false).toList();
                  }
                  if (_filtro.isNotEmpty) {
                    lista = lista.where((m) {
                      final esp = (m.especialidad ?? '').toLowerCase();
                      return m.nombre.toLowerCase().contains(_filtro) || esp.contains(_filtro);
                    }).toList();
                  }
                  if (lista.isEmpty) {
                    return const Center(child: Text('Sin mecánicos.'));
                  }
                  return ListView.separated(
                    itemCount: lista.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _card(lista[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Usuario m) {
    final disponible = m.disponible != false;
    final carga = m.ordenesActivas ?? 0;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: disponible ? Colors.green.shade50 : Colors.grey.shade200,
          child: Icon(Icons.engineering,
              color: disponible ? Colors.green.shade700 : Colors.grey),
        ),
        title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(Icons.build_outlined, m.especialidad ?? 'General'),
              _chip(Icons.schedule, 'Jornada: ${m.jornadaLegible}'),
              _chip(Icons.assignment_outlined, 'Órdenes activas: $carga'),
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor: disponible ? Colors.green.shade50 : Colors.grey.shade200,
          label: Text(
            disponible ? 'Disponible' : 'No disponible',
            style: TextStyle(
                fontSize: 12,
                color: disponible ? Colors.green.shade800 : Colors.grey.shade700),
          ),
        ),
        onTap: () => Navigator.pop(context, m),
      ),
    );
  }

  Widget _chip(IconData icono, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );
}
