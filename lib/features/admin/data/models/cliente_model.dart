import '../../domain/entities/cliente_entity.dart';

class ClienteModel extends ClienteEntity {
  const ClienteModel({
    required super.idCliente,
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
      idCliente: json['id'] as int,
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
      creado: DateTime.parse(json['creado'] as String),
      actualizado: DateTime.parse(json['actualizado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': idCliente,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
      'email': email,
      'rfc': rfc,
      'curp': curp,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
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
      'creado': creado.toIso8601String(),
      'actualizado': actualizado.toIso8601String(),
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
        'fecha_nacimiento': fechaNacimiento!.toIso8601String(),
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
