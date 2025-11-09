class PerfilEntity {
  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreCompleto;
  final String? telefono;
  final String rol; // 'cliente', 'moderador', 'administrador'
  final String? avatarUrl;
  final bool activo;
  final DateTime? ultimoAcceso;
  final DateTime creado;
  final DateTime actualizado;

  const PerfilEntity({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.avatarUrl,
    required this.activo,
    this.ultimoAcceso,
    required this.creado,
    required this.actualizado,
  });

  bool get esCliente => rol == 'cliente';
  bool get esModerador => rol == 'moderador';
  bool get esAdministrador => rol == 'administrador';
  bool get tienePermisosAdmin => esModerador || esAdministrador;
}
