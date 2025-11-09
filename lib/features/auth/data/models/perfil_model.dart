import '../../domain/entities/perfil_entity.dart';

class PerfilModel extends PerfilEntity {
  const PerfilModel({
    required super.id,
    required super.nombre,
    required super.apellidoPaterno,
    super.apellidoMaterno,
    required super.nombreCompleto,
    super.telefono,
    required super.rol,
    super.avatarUrl,
    required super.activo,
    super.ultimoAcceso,
    required super.creado,
    required super.actualizado,
  });

  /// Crear desde JSON de Supabase
  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellido_paterno'] as String,
      apellidoMaterno: json['apellido_materno'] as String?,
      nombreCompleto: json['nombre_completo'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      avatarUrl: json['avatar_url'] as String?,
      activo: json['activo'] as bool,
      ultimoAcceso: json['ultimo_acceso'] != null
          ? DateTime.parse(json['ultimo_acceso'] as String)
          : null,
      creado: DateTime.parse(json['creado'] as String),
      actualizado: DateTime.parse(json['actualizado'] as String),
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'telefono': telefono,
      'rol': rol,
      'avatar_url': avatarUrl,
      'activo': activo,
      'ultimo_acceso': ultimoAcceso?.toIso8601String(),
    };
  }

  /// Crear para registro nuevo
  Map<String, dynamic> toInsertJson() {
    return {
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'telefono': telefono,
      'rol': 'cliente', // Siempre cliente por defecto
      'activo': true,
    };
  }
}
