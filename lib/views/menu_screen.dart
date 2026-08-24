import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import 'cliente/catalogo_screen.dart';
import 'cliente/mis_reservas_screen.dart';
import 'crear_orden_screen.dart';
import 'gestion/clientes_admin_screen.dart';
import 'gestion/precios_screen.dart';
import 'gestion/reservas_internas_screen.dart';
import 'gestion/seguros_screen.dart';
import 'gestion/vehiculos_admin_screen.dart';
import 'login_screen.dart';
import 'ordenes_list_screen.dart';
import 'repuestos_screen.dart';
import 'vehiculos_screen.dart';

/// Menú principal. Muestra opciones según el rol del usuario.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final usuario = auth.usuario!;

    final opciones = _opcionesPorRol(usuario);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.person, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.nombre,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(usuario.rolLegible,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...opciones.map((o) => Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primario.withValues(alpha: 0.1),
                    child: Icon(o.icono, color: AppTheme.primario),
                  ),
                  title: Text(o.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(o.subtitulo),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => o.destino()),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Opciones de menú según el rol del usuario (actor).
  List<_OpcionMenu> _opcionesPorRol(Usuario usuario) {
    // Reutilizables
    final ordenes = _OpcionMenu('Órdenes de mantenimiento',
        'Revisar, autorizar y cerrar órdenes', Icons.assignment_outlined,
        () => const OrdenesListScreen());
    final repuestos = _OpcionMenu('Catálogo de repuestos', 'Stock y costos del almacén',
        Icons.inventory_2_outlined, () => const RepuestosScreen());
    final catalogo = _OpcionMenu('Catálogo de vehículos', 'Buscar y reservar un vehículo',
        Icons.directions_car_outlined, () => const CatalogoScreen());
    final clientes = _OpcionMenu('Gestión de clientes', 'Registrar y editar clientes',
        Icons.people_outline, () => const ClientesAdminScreen());
    final reservasInternas = _OpcionMenu('Reservas',
        usuario.esCajero ? 'Pagos, devoluciones y cancelaciones' : 'Ver todas las reservas',
        Icons.event_note_outlined, () => const ReservasInternasScreen());
    final gestionFlota = [
      _OpcionMenu('Gestión de vehículos', 'Registrar y editar la flota',
          Icons.garage_outlined, () => const VehiculosAdminScreen()),
      _OpcionMenu('Catálogo de precios', 'Tarifas por categoría de vehículo',
          Icons.sell_outlined, () => const PreciosScreen()),
      _OpcionMenu('Seguros y renovaciones', 'Registrar y renovar pólizas',
          Icons.shield_outlined, () => const SegurosScreen()),
    ];

    if (usuario.esCliente) {
      return [
        catalogo,
        _OpcionMenu('Mis reservas', 'Pagar, cancelar y ver mis reservas',
            Icons.receipt_long_outlined, () => const MisReservasScreen()),
      ];
    }
    if (usuario.esMecanico) {
      return [
        _OpcionMenu('Órdenes de mantenimiento', 'Órdenes asignadas y ejecución',
            Icons.assignment_outlined, () => const OrdenesListScreen()),
        repuestos,
      ];
    }
    if (usuario.esAdministrador) {
      return [clientes, ...gestionFlota];
    }
    if (usuario.esAsesor) {
      return [catalogo, clientes, reservasInternas];
    }
    if (usuario.esCajero) {
      return [reservasInternas];
    }
    // Jefe de Logística (por defecto): todo lo operativo + gestión.
    return [
      ordenes,
      _OpcionMenu('Vehículos por mantener', 'Revisar fechas y crear órdenes',
          Icons.directions_car_outlined, () => const VehiculosScreen()),
      _OpcionMenu('Crear orden de mantenimiento', 'Iniciar una nueva OM',
          Icons.add_box_outlined, () => const CrearOrdenScreen()),
      repuestos,
      clientes,
      ...gestionFlota,
      reservasInternas,
    ];
  }
}

class _OpcionMenu {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget Function() destino;
  _OpcionMenu(this.titulo, this.subtitulo, this.icono, this.destino);
}
