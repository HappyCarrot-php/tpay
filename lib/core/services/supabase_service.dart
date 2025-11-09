import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _initialized = false;

  /// Inicializar Supabase (llamar desde main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Obtener cliente de Supabase
  SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception('Supabase no ha sido inicializado. Llama a initialize() primero.');
    }
    return _client!;
  }

  /// Usuario actual
  User? get currentUser => _client?.auth.currentUser;

  /// ID del usuario actual
  String? get currentUserId => currentUser?.id;

  /// Email del usuario actual
  String? get currentUserEmail => currentUser?.email;

  /// Verificar si hay sesión activa
  bool get isAuthenticated => currentUser != null;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _client!.auth.onAuthStateChange;
}
