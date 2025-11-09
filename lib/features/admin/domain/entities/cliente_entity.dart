class ClienteEntity {
  final int idCliente;
  final String? usuarioId;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreCompleto;
  final String? telefono;
  final String? email;
  final String? rfc;
  final String? curp;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? ciudad;
  final String? estado;
  final String? codigoPostal;
  final String? identificacionTipo;
  final String? identificacionNumero;
  final String? fotoUrl;
  final double? calificacionCliente;
  final String? notas;
  final bool activo;
  final DateTime creado;
  final DateTime actualizado;

  const ClienteEntity({
    required this.idCliente,
    this.usuarioId,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.nombreCompleto,
    this.telefono,
    this.email,
    this.rfc,
    this.curp,
    this.fechaNacimiento,
    this.direccion,
    this.ciudad,
    this.estado,
    this.codigoPostal,
    this.identificacionTipo,
    this.identificacionNumero,
    this.fotoUrl,
    this.calificacionCliente,
    this.notas,
    required this.activo,
    required this.creado,
    required this.actualizado,
  });

  /// Obtener texto para dropdown: "ID - Nombre Completo"
  String get displayText => '#$idCliente - $nombreCompleto';
  
  /// Obtener iniciales para avatar
  String get iniciales {
    final primera = nombre.isNotEmpty ? nombre[0] : '';
    final segunda = apellidoPaterno.isNotEmpty ? apellidoPaterno[0] : '';
    return '$primera$segunda'.toUpperCase();
  }
}
