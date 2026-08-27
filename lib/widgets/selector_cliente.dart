import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/gestion_service.dart';

/// «include» **Buscar Cliente** — componente reutilizable e idéntico en toda la app.
///
/// Campo con el cliente elegido; al tocarlo abre el mismo buscador (lista de
/// clientes con filtro), sin importar desde dónde se llame.
class SelectorCliente extends StatelessWidget {
  final Cliente? value;
  final ValueChanged<Cliente> onChanged;
  final String label;

  const SelectorCliente({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Cliente',
  });

  static String texto(Cliente c) => c.razonSocial ?? c.numeroDocumento;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegido = await showDialog<Cliente>(
          context: context,
          builder: (_) => const _BuscadorClienteDialog(),
        );
        if (elegido != null) onChanged(elegido);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.person_outline),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          value == null ? 'Buscar cliente…' : texto(value!),
          style: TextStyle(
            color: value == null ? Colors.black54 : Colors.black,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Diálogo del buscador de clientes (lista + filtro). Rendering único del caso
/// «include» Buscar Cliente.
class _BuscadorClienteDialog extends StatefulWidget {
  const _BuscadorClienteDialog();

  @override
  State<_BuscadorClienteDialog> createState() => _BuscadorClienteDialogState();
}

class _BuscadorClienteDialogState extends State<_BuscadorClienteDialog> {
  final _svc = GestionService();
  late Future<List<Cliente>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _futuro = _svc.listarClientes();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nombre o documento…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (t) => setState(() => _filtro = t.toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Cliente>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('${snap.error}'));
                  final todos = snap.data ?? [];
                  final lista = _filtro.isEmpty
                      ? todos
                      : todos.where((c) {
                          final t = '${c.razonSocial ?? ''} ${c.numeroDocumento}'
                              .toLowerCase();
                          return t.contains(_filtro);
                        }).toList();
                  if (lista.isEmpty) {
                    return const Center(child: Text('Sin clientes.'));
                  }
                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final c = lista[i];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(c.razonSocial ?? c.numeroDocumento),
                        subtitle: Text(
                            'Doc: ${c.numeroDocumento}${c.telefono != null ? '  ·  ${c.telefono}' : ''}'),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
