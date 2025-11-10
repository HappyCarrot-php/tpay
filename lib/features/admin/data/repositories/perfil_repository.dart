import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class PerfilModel {
  final String id;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? avatarUrl;
  final bool activo;

  PerfilModel({
    required this.id,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.avatarUrl,
    required this.activo,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String?,
      apellidoPaterno: json['apellido_paterno'] as String?,
      apellidoMaterno: json['apellido_materno'] as String?,
      nombreCompleto: json['nombre_completo'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      avatarUrl: json['avatar_url'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class PerfilRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener perfil del usuario actual
  Future<PerfilModel?> obtenerPerfilActual() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return PerfilModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // Obtener email del usuario actual
  String? obtenerEmailActual() {
    return _supabase.auth.currentUser?.email;
  }
}
