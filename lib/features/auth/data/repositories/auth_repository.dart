import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/perfil_model.dart';

class AuthRepository {
  final SupabaseService _supabaseService = SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  /// Login con email y password
  Future<PerfilModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Autenticar con Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      // Obtener perfil del usuario
      final perfil = await obtenerPerfilActual();
      
      if (!perfil.activo) {
        await _client.auth.signOut();
        throw Exception('Tu cuenta ha sido desactivada. Contacta al administrador.');
      }

      return perfil;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Registro de nuevo usuario (siempre rol cliente)
  /// Email es opcional - si no se proporciona, se genera uno automático
  Future<PerfilModel> register({
    String? email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  }) async {
    try {
      // Si no se proporciona email, generar uno basado en nombre
      final emailToUse = email ??
          '${nombre.toLowerCase().replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}@tpay.local';

      // Registrar en Supabase Auth
      final response = await _client.auth.signUp(
        email: emailToUse,
        password: password,
        data: {
          'nombre': nombre,
          'apellido_paterno': apellidoPaterno,
          if (apellidoMaterno != null) 'apellido_materno': apellidoMaterno,
          if (telefono != null) 'telefono': telefono,
        },
      );

      if (response.user == null) {
        throw Exception('No se pudo crear la cuenta');
      }

      // El perfil se crea automáticamente con el trigger
      // Esperar un momento para que se cree
      await Future.delayed(const Duration(milliseconds: 500));

      // Obtener el perfil creado
      final perfil = await obtenerPerfilActual();

      return perfil;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtener perfil del usuario actual
  Future<PerfilModel> obtenerPerfilActual() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      final response = await _client
          .from(SupabaseConstants.perfilesTable)
          .select()
          .eq('id', userId)
          .single();

      return PerfilModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Verificar si hay sesión activa
  bool isAuthenticated() {
    return _supabaseService.isAuthenticated;
  }

  /// Obtener rol del usuario actual
  Future<String> obtenerRolUsuario() async {
    try {
      final response = await _client
          .rpc(SupabaseConstants.rpcObtenerRolUsuario);
      
      return response as String;
    } catch (e) {
      throw Exception('Error al obtener rol: $e');
    }
  }

  /// Verificar si tiene permisos de admin/moderador
  Future<bool> tienePermisosAdmin() async {
    try {
      final response = await _client
          .rpc(SupabaseConstants.rpcTienePermisosAdmin);
      
      return response as bool;
    } catch (e) {
      return false;
    }
  }

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  /// Manejar errores de autenticación
  String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return 'Email o contraseña incorrectos';
      case '422':
        return 'Email inválido';
      case '429':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return error.message;
    }
  }
}
