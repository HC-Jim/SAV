/// Usuario del sistema. Actores con acceso: Cliente, Administrador y Jefe de
/// Logística. (MECANICO existe como dato asignable a la orden, sin acceso.)
class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol; // JEFE_LOGISTICA | MECANICO

  // Datos del mecánico (para «Buscar Mecánico»); opcionales.
  final String? jornada; // MAÑANA | TARDE | NOCHE
  final String? especialidad;
  final String? telefono;
  final bool? disponible;
  final int? ordenesActivas;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.jornada,
    this.especialidad,
    this.telefono,
    this.disponible,
    this.ordenesActivas,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: (json['email'] ?? '') as String,
        rol: json['rol'] as String,
        jornada: json['jornada'] as String?,
        especialidad: json['especialidad'] as String?,
        telefono: json['telefono'] as String?,
        disponible: json['disponible'] as bool?,
        ordenesActivas: json['ordenes_activas'] as int?,
      );

  String get jornadaLegible {
    switch (jornada) {
      case 'MAÑANA':
        return 'Mañana';
      case 'TARDE':
        return 'Tarde';
      case 'NOCHE':
        return 'Noche';
      default:
        return jornada ?? '-';
    }
  }

  bool get esJefe => rol == 'JEFE_LOGISTICA';
  bool get esCliente => rol == 'CLIENTE';
  bool get esAdministrador => rol == 'ADMINISTRADOR';

  String get rolLegible {
    switch (rol) {
      case 'JEFE_LOGISTICA':
        return 'Jefe de Logística';
      case 'MECANICO':
        return 'Mecánico'; // dato: el mecánico se asigna a la orden, pero no accede
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'CLIENTE':
        return 'Cliente';
      default:
        return rol;
    }
  }
}
