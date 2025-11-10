import '../../domain/entities/cliente_entity.dart';

class ClienteModel extends ClienteEntity {
  const ClienteModel({
    required super.id,
    super.usuarioId,
    required super.nombre,
    required super.apellidoPaterno,
    super.apellidoMaterno,
    required super.nombreCompleto,
    super.telefono,
    super.email,
    super.rfc,
    super.curp,
    super.fechaNacimiento,
    super.direccion,
    super.ciudad,
    super.estado,
    super.codigoPostal,
    super.identificacionTipo,
    super.identificacionNumero,
    super.fotoUrl,
    super.calificacionCliente,
    super.notas,
    required super.activo,
    required super.creado,
    required super.actualizado,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id_cliente'] as int, // Campo de BD es id_cliente
      usuarioId: json['usuario_id'] as String?,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellido_paterno'] as String,
      apellidoMaterno: json['apellido_materno'] as String?,
      nombreCompleto: json['nombre_completo'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      rfc: json['rfc'] as String?,
      curp: json['curp'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      estado: json['estado'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      identificacionTipo: json['identificacion_tipo'] as String?,
      identificacionNumero: json['identificacion_numero'] as String?,
      fotoUrl: json['foto_url'] as String?,
      calificacionCliente: json['calificacion_cliente'] != null
          ? (json['calificacion_cliente'] as num).toDouble()
          : null,
      notas: json['notas'] as String?,
      activo: json['activo'] as bool? ?? true,
      // Manejo flexible de timestamps (created_at, creado, fecha_creacion)
      creado: _parseTimestamp(json, ['creado', 'created_at', 'fecha_creacion']) ?? DateTime.now(),
      actualizado: _parseTimestamp(json, ['actualizado', 'updated_at', 'fecha_actualizacion']) ?? DateTime.now(),
    );
  }

  // Helper para parsear timestamps con múltiples nombres posibles
  static DateTime? _parseTimestamp(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      if (json[key] != null) {
        try {
          return DateTime.parse(json[key] as String);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'telefono': telefono,
      'email': email,
      'rfc': rfc,
      'curp': curp,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0], // Solo fecha
      'direccion': direccion,
      'ciudad': ciudad,
      'estado': estado,
      'codigo_postal': codigoPostal,
      'identificacion_tipo': identificacionTipo,
      'identificacion_numero': identificacionNumero,
      'foto_url': fotoUrl,
      'calificacion_cliente': calificacionCliente,
      'notas': notas,
      'activo': activo,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (usuarioId != null) 'usuario_id': usuarioId,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      if (apellidoMaterno != null) 'apellido_materno': apellidoMaterno,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (rfc != null) 'rfc': rfc,
      if (curp != null) 'curp': curp,
      if (fechaNacimiento != null)
        'fecha_nacimiento': fechaNacimiento!.toIso8601String().split('T')[0],
      if (direccion != null) 'direccion': direccion,
      if (ciudad != null) 'ciudad': ciudad,
      if (estado != null) 'estado': estado,
      if (codigoPostal != null) 'codigo_postal': codigoPostal,
      if (identificacionTipo != null) 'identificacion_tipo': identificacionTipo,
      if (identificacionNumero != null) 'identificacion_numero': identificacionNumero,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (calificacionCliente != null) 'calificacion_cliente': calificacionCliente,
      if (notas != null) 'notas': notas,
      'activo': activo,
    };
  }
}
