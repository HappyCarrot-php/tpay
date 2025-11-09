class SupabaseConstants {
  static const String supabaseUrl = 'https://ktayokopgaulinulkkbf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YXlva29wZ2F1bGludWxra2JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2OTM4MzYsImV4cCI6MjA3ODI2OTgzNn0.S56hklAapHCNcbe5i7hDsqxVUA71opnq0Wt0tUhdaDU';
  
  // Nombres de tablas según la BD
  static const String perfilesTable = 'perfiles';
  static const String clientesTable = 'clientes';
  static const String movimientosTable = 'movimientos';
  static const String abonosTable = 'abonos';
  static const String historialAccesosTable = 'historial_accesos';
  
  // Vistas
  static const String vistaPrestamosActivos = 'vista_prestamos_activos';
  static const String vistaResumenClientes = 'vista_resumen_clientes';
  static const String vistaEstadisticasDashboard = 'vista_estadisticas_dashboard';
  
  // Funciones RPC
  static const String rpcObtenerPerfilActual = 'obtener_perfil_actual';
  static const String rpcObtenerRolUsuario = 'obtener_rol_usuario';
  static const String rpcTienePermisosAdmin = 'tiene_permisos_admin';
  static const String rpcRegistrarMovimiento = 'registrar_movimiento';
  static const String rpcRegistrarAbono = 'registrar_abono';
  static const String rpcCambiarRolUsuario = 'cambiar_rol_usuario';
  
  // Constantes adicionales
  static const String vistaPrestamosActivosView = vistaPrestamosActivos;
  static const String registrarMovimientoRpc = rpcRegistrarMovimiento;
  static const String registrarAbonoRpc = rpcRegistrarAbono;
}
