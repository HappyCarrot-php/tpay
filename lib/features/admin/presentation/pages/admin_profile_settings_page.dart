import 'package:flutter/material.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../../../core/services/profile_image_service.dart';
import '../../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfileSettingsPage extends StatefulWidget {
  const AdminProfileSettingsPage({super.key});

  @override
  State<AdminProfileSettingsPage> createState() => _AdminProfileSettingsPageState();
}

class _AdminProfileSettingsPageState extends State<AdminProfileSettingsPage> {
  final _perfilRepo = PerfilRepository();
  final _supabase = SupabaseService().client;
  final ProfileImageService _profileImageService = ProfileImageService();
  
  bool _isLoading = true;
  String? _nombre;
  String? _apellidoPaterno;
  String? _apellidoMaterno;
  String? _telefono;
  String? _email;
  String? _rol;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await _perfilRepo.obtenerPerfilActual();
      final email = _perfilRepo.obtenerEmailActual();
      
      // Obtener foto de perfil si existe
      String? fotoUrl;
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final response = await _supabase
              .from('perfiles')
              .select('foto_url')
              .eq('usuario_id', userId)
              .single();
          fotoUrl = response['foto_url'] as String?;
        }
      } catch (e) {
        // Ignorar si no hay foto
      }
      
      setState(() {
        _nombre = perfil?.nombre;
        _apellidoPaterno = perfil?.apellidoPaterno;
        _apellidoMaterno = perfil?.apellidoMaterno;
        _telefono = perfil?.telefono;
        _email = email;
        _rol = perfil?.rol;
        _fotoUrl = fotoUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                          backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                          child: _fotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF00BCD4),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF00BCD4),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              onPressed: _cambiarFoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Información Personal
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          _buildInfoRow('Nombre', _nombre ?? 'No disponible'),
                          _buildInfoRow('Apellido Paterno', _apellidoPaterno ?? 'No disponible'),
                          if (_apellidoMaterno != null)
                            _buildInfoRow('Apellido Materno', _apellidoMaterno!),
                          _buildInfoRow('Teléfono', _telefono ?? 'No disponible'),
                          _buildInfoRow('Email', _email ?? 'No disponible'),
                          _buildInfoRow('Rol', _getRolTexto(_rol ?? 'cliente')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seguridad
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seguridad',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.lock, color: Color(0xFF00BCD4)),
                            title: const Text('Cambiar Contraseña'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _cambiarContrasena,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _cambiarContrasena() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final dialogContext = context;
                  Navigator.pop(context); // Cerrar el diálogo del formulario
                  
                  bool operacionExitosa = false;
                  String? mensajeError;

                  try {
                    // Obtener email del usuario actual
                    final email = _supabase.auth.currentUser?.email;
                    if (email == null) {
                      throw Exception('No se pudo obtener el email del usuario');
                    }

                    // Verificar contraseña actual haciendo login temporal
                    final response = await _supabase.auth.signInWithPassword(
                      email: email,
                      password: currentPasswordController.text,
                    );

                    if (response.user == null) {
                      throw Exception('Contraseña actual incorrecta');
                    }

                    // Si llegamos aquí, la contraseña actual es correcta
                    // Ahora cambiamos la contraseña
                    final updateResponse = await _supabase.auth.updateUser(
                      UserAttributes(password: newPasswordController.text),
                    );

                    if (updateResponse.user != null) {
                      operacionExitosa = true;
                    } else {
                      throw Exception('No se pudo actualizar la contraseña');
                    }
                  } catch (e) {
                    operacionExitosa = false;
                    
                    if (e.toString().contains('Invalid login') || 
                        e.toString().contains('Invalid') ||
                        e.toString().contains('incorrecta')) {
                      mensajeError = 'Contraseña actual incorrecta';
                    } else if (e.toString().contains('Network')) {
                      mensajeError = 'Error de conexión';
                    } else {
                      mensajeError = 'Error al cambiar contraseña';
                    }
                  }
                  
                  // Mostrar resultado directo con diálogo
                  if (dialogContext.mounted) {
                    if (operacionExitosa) {
                      showDialog(
                        context: dialogContext,
                        builder: (context) => AlertDialog(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                          title: const Text('¡Éxito!'),
                          content: const Text('Contraseña actualizada correctamente'),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showDialog(
                        context: dialogContext,
                        builder: (context) => AlertDialog(
                          icon: const Icon(Icons.error, color: Colors.red, size: 60),
                          title: const Text('Error'),
                          content: Text(mensajeError ?? 'Error al cambiar contraseña'),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getRolTexto(String rol) {
    switch (rol) {
      case 'administrador':
        return 'Administrador';
      case 'moderador':
        return 'Moderador';
      default:
        return 'Cliente';
    }
  }

  Future<void> _cambiarFoto() async {
    try {
      final newUrl = await _profileImageService.pickAndUploadProfilePhoto(context);
      if (newUrl == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _fotoUrl = newUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
