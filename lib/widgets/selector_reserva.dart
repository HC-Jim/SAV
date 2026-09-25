import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../services/alquiler_service.dart';

/// «include» **Buscar Reserva** — componente reutilizable.
///
/// Muestra el campo con la reserva elegida y, al tocarlo, abre el buscador
/// (lista de las reservas del Cliente pendientes de pago). Lo usa la interfaz
/// «Realizar Pago» para obtener la reserva a pagar.
class SelectorReserva extends StatelessWidget {
  final Reserva? value;
  final ValueChanged<Reserva> onChanged;
  final String label;

  /// Si es true, solo ofrece reservas en estado "Por pagar".
  final bool soloPorPagar;

  const SelectorReserva({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Buscar reserva',
    this.soloPorPagar = true,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return InkWell(
      onTap: () async {
        final elegida = await Navigator.of(context).push<Reserva>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _BuscadorReservaScreen(soloPorPagar: soloPorPagar),
          ),
        );
        if (elegida != null) onChanged(elegida);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.receipt_long_outlined),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          v == null
              ? 'Buscar reserva…'
              : 'Reserva #${v.id} · ${v.vehiculo?.descripcion ?? 'Vehículo ${v.vehiculoId}'}',
          style: TextStyle(
            color: v == null ? Colors.black54 : Colors.black,
            fontWeight: v == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BuscadorReservaScreen extends StatefulWidget {
  final bool soloPorPagar;
  const _BuscadorReservaScreen({required this.soloPorPagar});

  @override
  State<_BuscadorReservaScreen> createState() => _BuscadorReservaScreenState();
}

class _BuscadorReservaScreenState extends State<_BuscadorReservaScreen> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _futuro = _svc.misReservas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar reserva')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'N° de reserva, placa o modelo…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Reserva>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('${snap.error}'));
                  var lista = snap.data ?? [];
                  if (widget.soloPorPagar) {
                    lista = lista
                        .where((r) => r.estado == EstadoReserva.porPagar)
                        .toList();
                  }
                  if (_filtro.isNotEmpty) {
                    lista = lista.where((r) => (
                            '#${r.id} ${r.vehiculo?.descripcion ?? ''}')
                        .toLowerCase()
                        .contains(_filtro)).toList();
                  }
                  if (lista.isEmpty) {
                    return const Center(child: Text('No tienes reservas por pagar.'));
                  }
                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final r = lista[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(
                              'Reserva #${r.id} · ${EstadoReserva.legible(r.estado)}'),
                          subtitle: Text(
                              '${r.vehiculo?.descripcion ?? 'Vehículo ${r.vehiculoId}'}\n'
                              'Alquiler: S/ ${r.montoTotalEstimado.toStringAsFixed(2)} · '
                              'Garantía: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
                          isThreeLine: true,
                          onTap: () => Navigator.pop(context, r),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
