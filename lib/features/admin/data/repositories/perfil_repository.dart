import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_data_cache.dart';
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
      AppDataCache().cachePerfil(Map<String, dynamic>.from(response));
      return PerfilModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // Obtener email del usuario actual
  String? obtenerEmailActual() {
    return _supabase.auth.currentUser?.email;
  }

  Future<List<PerfilModel>> obtenerPerfiles({bool soloActivos = true}) async {
    try {
      var query = _supabase.from('perfiles').select();
      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query.order('creado', ascending: true);

      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      AppDataCache().cachePerfiles(rows);

      return rows.map(PerfilModel.fromJson).toList();
    } catch (e) {
      throw Exception('Error al obtener perfiles: $e');
    }
  }
}
