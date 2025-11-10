import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/repositories/perfil_repository.dart';
import '../../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

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
      final fileExt = image.path.split('.').last;
      final fileName = '$userId.$fileExt';
      final filePath = 'avatars/$fileName';

      // Subir a Supabase Storage
      await _supabase.storage.from('profiles').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );

      // Obtener URL pública
      final publicUrl = _supabase.storage.from('profiles').getPublicUrl(filePath);

      // Actualizar en la tabla de perfiles
      await _supabase.from('perfiles').update({
        'foto_url': publicUrl,
      }).eq('usuario_id', userId);

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
