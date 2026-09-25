import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import 'buscar_orden_screen.dart';
import 'cliente/realizar_pago_screen.dart';
import 'cliente/reservar_vehiculo_screen.dart';
import 'crear_orden_screen.dart';
import 'gestion/cupones_screen.dart';
import 'gestion/registrar_seguro_screen.dart';
import 'gestion/seguros_screen.dart';
import 'gestion/vehiculos_screen.dart';
import 'login_screen.dart';

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
  // Alcance vigente: Cliente, Administrador y Jefe de Logística.
  List<_OpcionMenu> _opcionesPorRol(Usuario usuario) {
    if (usuario.esCliente) {
      return [
        // Generar Orden de Reserva: interfaz → «include» Buscar Vehículo.
        _OpcionMenu('Reservar vehículo', 'Buscar vehículo y generar la orden de reserva',
            Icons.event_available_outlined, () => const ReservarVehiculoScreen()),
        // Registrar Pago de Orden de Reserva: interfaz → «include» Buscar Reserva.
        _OpcionMenu('Realizar pago', 'Elegir la reserva y pagar (tarjeta o Yape)',
            Icons.payments_outlined, () => const RealizarPagoScreen()),
      ];
    }
    if (usuario.esAdministrador) {
      return [
        // Vehículos (CRUD): editar datos y/o precio, ver variación, crear nuevo.
        _OpcionMenu('Vehículos', 'Editar datos y precios, o crear un vehículo',
            Icons.directions_car_outlined, () => const VehiculosScreen()),
        // Registrar Seguro (interfaz completa).
        _OpcionMenu('Registrar seguro', 'Registrar una póliza de seguro',
            Icons.add_moderator_outlined, () => const RegistrarSeguroScreen()),
        // Buscar Seguro (interfaz de consulta).
        _OpcionMenu('Buscar seguro', 'Consultar las pólizas registradas',
            Icons.shield_outlined, () => const SegurosScreen()),
        // Cupones (tabla de descuentos).
        _OpcionMenu('Cupones', 'Ver los cupones y su estado',
            Icons.local_offer_outlined, () => const CuponesScreen()),
      ];
    }
    if (usuario.esJefe) {
      // Jefe de Logística: Registrar Orden de Mantenimiento
      // («include» Buscar Vehículo y Buscar Mecánico).
      return [
        _OpcionMenu('Registrar orden de mantenimiento',
            'Buscar vehículo, asignar mecánico y registrar la orden',
            Icons.add_box_outlined, () => const CrearOrdenScreen()),
        _OpcionMenu('Buscar orden de mantenimiento',
            'Consultar las órdenes registradas',
            Icons.manage_search_outlined, () => const BuscarOrdenScreen()),
      ];
    }
    // Rol sin acceso (Asesor de Ventas, Cajero y Mecánico: eliminados del sistema).
    return [];
  }
}

class _OpcionMenu {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget Function() destino;
  _OpcionMenu(this.titulo, this.subtitulo, this.icono, this.destino);
}
