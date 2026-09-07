import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../services/alquiler_service.dart';

/// «include» **Buscar Orden de Reserva** — componente reutilizable.
///
/// Lista las órdenes de reserva (con búsqueda por #, placa o modelo) y, al
/// tocar una, dispara [onSeleccionar]. Se puede filtrar por estados. El caso
/// incluido se ve igual desde cualquier flujo del Cajero (devolver garantía,
/// emitir comprobante, etc.).
class BuscarReserva extends StatefulWidget {
  /// Estados a mostrar (vacío = todos).
  final Set<String> estados;
  final String accionLabel;
  final IconData accionIcono;
  final void Function(Reserva) onSeleccionar;

  /// Cambiar este valor fuerza recargar la lista (p. ej. tras una acción).
  final int reloadToken;

  const BuscarReserva({
    super.key,
    required this.onSeleccionar,
    this.estados = const {},
    this.accionLabel = 'Seleccionar',
    this.accionIcono = Icons.chevron_right,
    this.reloadToken = 0,
  });

  @override
  State<BuscarReserva> createState() => _BuscarReservaState();
}

class _BuscarReservaState extends State<BuscarReserva> {
  final _svc = AlquilerService();
  late Future<List<Reserva>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant BuscarReserva old) {
    super.didUpdateWidget(old);
    if (old.reloadToken != widget.reloadToken) _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarTodas());

  bool _coincide(Reserva r) {
    if (_filtro.isEmpty) return true;
    final v = r.vehiculo;
    final texto = '#${r.id} ${v?.placa ?? ''} ${v?.marca ?? ''} ${v?.modelo ?? ''}'.toLowerCase();
    return texto.contains(_filtro);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por N°, placa o modelo…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
            ],
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
                if (widget.estados.isNotEmpty) {
                  lista = lista.where((r) => widget.estados.contains(r.estado)).toList();
                }
                lista = lista.where(_coincide).toList();
                if (lista.isEmpty) {
                  return const Center(child: Text('No hay órdenes de reserva.'));
                }
                return ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _card(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Reserva r) {
    final v = r.vehiculo;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('#${r.id}')),
        title: Text(v != null
            ? '${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})'.trim()
            : 'Vehículo ${r.vehiculoId ?? '-'}'),
        subtitle: Text('Del ${r.fechaInicio ?? '-'} al ${r.fechaFin ?? '-'}  ·  '
            '${EstadoReserva.legible(r.estado)}\n'
            'Total: S/ ${r.montoTotalEstimado.toStringAsFixed(2)}  ·  '
            'Garantía: S/ ${r.garantiaMonto.toStringAsFixed(2)}'),
        isThreeLine: true,
        trailing: FilledButton.tonalIcon(
          onPressed: () => widget.onSeleccionar(r),
          icon: Icon(widget.accionIcono, size: 18),
          label: Text(widget.accionLabel),
        ),
      ),
    );
  }
}
