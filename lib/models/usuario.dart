/// Actor del proceso: Jefe de Logistica o Mecanico.
class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol; // JEFE_LOGISTICA | MECANICO

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        rol: json['rol'] as String,
      );

  bool get esJefe => rol == 'JEFE_LOGISTICA';
  bool get esMecanico => rol == 'MECANICO';
  bool get esCliente => rol == 'CLIENTE';
  bool get esAdministrador => rol == 'ADMINISTRADOR';
  bool get esAsesor => rol == 'ASESOR_VENTAS';
  bool get esCajero => rol == 'CAJERO';

  String get rolLegible {
    switch (rol) {
      case 'JEFE_LOGISTICA':
        return 'Jefe de Logística';
      case 'MECANICO':
        return 'Mecánico';
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'ASESOR_VENTAS':
        return 'Asesor de Ventas';
      case 'CAJERO':
        return 'Cajero';
      case 'CLIENTE':
        return 'Cliente';
      default:
        return rol;
    }
  }
}
