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
      // Sanitizar y validar inputs
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedPassword = password.trim();
      
      // Validar formato de email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(sanitizedEmail)) {
        throw Exception('Formato de email inválido');
      }
      
      // Validar longitud de contraseña
      if (sanitizedPassword.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }
      
      // Detectar caracteres sospechosos (intentos de inyección)
      final suspiciousChars = RegExp(r'[<>{}()\[\]\\|;$`]');
      if (suspiciousChars.hasMatch(sanitizedEmail)) {
        throw Exception('El email contiene caracteres no permitidos');
      }
      
      // Autenticar con Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: sanitizedEmail,
        password: sanitizedPassword,
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
  Future<PerfilModel> register({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  }) async {
    try {
      // Registrar en Supabase Auth
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nombre': nombre,
          'apellido_paterno': apellidoPaterno,
          'apellido_materno': apellidoMaterno ?? '',
          'telefono': telefono ?? '',
        },
      );

      if (response.user == null) {
        throw Exception('No se pudo crear la cuenta');
      }

      // Esperar a que el trigger cree el perfil
      await Future.delayed(const Duration(seconds: 2));

      // Intentar obtener el perfil (máximo 5 intentos)
      PerfilModel? perfil;
      for (int i = 0; i < 5; i++) {
        try {
          final perfilData = await _client
              .from(SupabaseConstants.perfilesTable)
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (perfilData != null) {
            perfil = PerfilModel.fromJson(perfilData);
            break;
          }

          // Si no existe en el último intento, crearlo manualmente
          if (i == 4) {
            await _client.from(SupabaseConstants.perfilesTable).insert({
              'id': response.user!.id,
              'nombre': nombre,
              'apellido_paterno': apellidoPaterno,
              'apellido_materno': apellidoMaterno,
              'telefono': telefono,
              'rol': 'cliente',
              'activo': true,
            });

            final perfilCreado = await _client
                .from(SupabaseConstants.perfilesTable)
                .select()
                .eq('id', response.user!.id)
                .single();

            perfil = PerfilModel.fromJson(perfilCreado);
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          if (i == 4) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (perfil == null) {
        throw Exception('No se pudo crear el perfil');
      }

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
    final message = error.message.toLowerCase();
    
    // Detectar email duplicado
    if (message.contains('already registered') || 
        message.contains('already been registered') ||
        message.contains('user already registered')) {
      return 'Este email ya está registrado. Usa otro o inicia sesión.';
    }
    
    switch (error.statusCode) {
      case '400':
        return 'Email o contraseña incorrectos';
      case '422':
        if (message.contains('invalid')) {
          return 'Email inválido. Verifica el formato.';
        }
        return 'Datos inválidos. Verifica la información.';
      case '429':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return error.message;
    }
  }
}
