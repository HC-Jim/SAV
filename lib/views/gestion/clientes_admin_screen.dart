import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/api_client.dart';
import '../../services/gestion_service.dart';

/// Mantener Cliente (CRUD) - Jefe de Logística.
class ClientesAdminScreen extends StatefulWidget {
  const ClientesAdminScreen({super.key});
  @override
  State<ClientesAdminScreen> createState() => _ClientesAdminScreenState();
}

class _ClientesAdminScreenState extends State<ClientesAdminScreen> {
  final _svc = GestionService();
  late Future<List<Cliente>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => setState(() => _futuro = _svc.listarClientes());

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _guardar(Cliente? c, Map<String, dynamic> datos) async {
    try {
      if (c == null) {
        await _svc.crearCliente(datos);
      } else {
        await _svc.actualizarCliente(c.id, datos);
      }
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  Future<void> _eliminar(Cliente c) async {
    try {
      await _svc.eliminarCliente(c.id);
      if (mounted) _cargar();
    } on ApiException catch (e) {
      _snack(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Cliente>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final lista = snap.data ?? [];
          if (lista.isEmpty) return const Center(child: Text('Sin clientes.'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: lista
                .map((c) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(c.razonSocial ?? c.numeroDocumento),
                        subtitle: Text('${c.tipoDocumento ?? ''} ${c.numeroDocumento}  ·  ${c.telefono ?? ''}'),
                        onTap: () => _abrirForm(c),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmarEliminar(c),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar ${c.razonSocial ?? c.numeroDocumento}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) _eliminar(c);
  }

  Future<void> _abrirForm(Cliente? c) async {
    final tipo = TextEditingController(text: c?.tipoDocumento ?? 'DNI');
    final numero = TextEditingController(text: c?.numeroDocumento ?? '');
    final razon = TextEditingController(text: c?.razonSocial ?? '');
    final licencia = TextEditingController(text: c?.licenciaConducir ?? '');
    final telefono = TextEditingController(text: c?.telefono ?? '');
    final correo = TextEditingController(text: c?.correo ?? '');

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c == null ? 'Nuevo cliente' : 'Editar cliente'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(tipo, 'Tipo documento (DNI/RUC/CE)'),
            _campo(numero, 'Número de documento'),
            _campo(razon, 'Nombre / Razón social'),
            _campo(licencia, 'Licencia de conducir'),
            _campo(telefono, 'Teléfono'),
            _campo(correo, 'Correo'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'tipo_documento': tipo.text.trim(),
              'numero_documento': numero.text.trim(),
              'razon_social': razon.text.trim(),
              'licencia_conducir': licencia.text.trim(),
              'telefono': telefono.text.trim(),
              'correo': correo.text.trim(),
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (datos != null) _guardar(c, datos);
  }

  Widget _campo(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: c, decoration: InputDecoration(labelText: label)),
      );
}
