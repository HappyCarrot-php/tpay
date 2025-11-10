import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/repositories/perfil_repository.dart';
import '../../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class AdminProfileSettingsPage extends StatefulWidget {
  const AdminProfileSettingsPage({super.key});

  @override
  State<AdminProfileSettingsPage> createState() => _AdminProfileSettingsPageState();
}

class _AdminProfileSettingsPageState extends State<AdminProfileSettingsPage> {
  final _perfilRepo = PerfilRepository();
  final _supabase = SupabaseService().client;
  final _imagePicker = ImagePicker();
  
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
                  
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (loadingContext) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Cambiando contraseña...'),
                        ],
                      ),
                    ),
                  );

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
                      // Éxito
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(); // Cerrar loading
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Contraseña actualizada correctamente'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      throw Exception('No se pudo actualizar la contraseña');
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(); // Cerrar loading
                      
                      String errorMessage = 'Error al cambiar contraseña';
                      
                      if (e.toString().contains('Invalid login') || 
                          e.toString().contains('Invalid') ||
                          e.toString().contains('incorrecta')) {
                        errorMessage = '❌ Contraseña actual incorrecta';
                      } else if (e.toString().contains('Network')) {
                        errorMessage = '❌ Error de conexión';
                      }
                      
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
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
      // Mostrar opciones (Cámara o Galería)
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar Foto de Perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00BCD4)),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00BCD4)),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Seleccionar imagen
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100, // Máxima calidad para el crop
      );

      if (pickedImage == null) return;

      // Recortar imagen (ajustar marco como apps modernas)
      final ImageCropper cropper = ImageCropper();
      final CroppedFile? croppedFile = await cropper.cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Cuadrado para avatar
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: const Color(0xFF00BCD4),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Ajustar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      // Usar la imagen recortada
      final image = XFile(croppedFile.path);

      // Mostrar loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener el ID del usuario
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Leer el archivo
      final bytes = await File(image.path).readAsBytes();
      final fileExt = 'jpg'; // Siempre usar jpg para compatibilidad
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_${userId}_$timestamp.$fileExt';

      // Subir nuevo archivo a Supabase Storage con upsert
      await _supabase.storage.from('profiles').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // Obtener URL pública
      final publicUrl = _supabase.storage.from('profiles').getPublicUrl(fileName);

      // Actualizar en la tabla de perfiles
      await _supabase.from('perfiles').update({
        'foto_url': publicUrl,
      }).eq('user_id', userId);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      setState(() {
        _fotoUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
