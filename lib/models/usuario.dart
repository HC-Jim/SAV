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

  String get rolLegible => esJefe ? 'Jefe de Logística' : 'Mecánico';
}
