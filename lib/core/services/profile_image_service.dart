import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ProfileImageService {
  ProfileImageService({
    ImagePicker? imagePicker,
    ImageCropper? imageCropper,
    SupabaseClient? supabaseClient,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _imageCropper = imageCropper ?? ImageCropper(),
        _supabase = supabaseClient ?? SupabaseService().client;

  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;
  final SupabaseClient _supabase;

  Future<String?> pickAndUploadProfilePhoto(BuildContext context) async {
    final source = await _promptImageSource(context);
    if (source == null) {
      return null;
    }

    final XFile? pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedImage == null) {
      return null;
    }

    final XFile processedImage = await _tryCropImage(pickedImage);

    if (!context.mounted) {
      return null;
    }

    await _showBlockingLoader(context);

    try {
      final url = await _uploadAndPersist(processedImage);
      _closeBlockingLoader(context);
      return url;
    } catch (error) {
      _closeBlockingLoader(context);
      rethrow;
    }
  }

  Future<ImageSource?> _promptImageSource(BuildContext context) {
    return showDialog<ImageSource>(
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
  }

  Future<XFile> _tryCropImage(XFile original) async {
    try {
      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: original.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: const Color(0xFF00BCD4),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Ajustar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
    } catch (_) {
      // Ignorar errores de recorte y continuar con la imagen original.
    }

    return original;
  }

  Future<String> _uploadAndPersist(XFile image) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final bytes = await File(image.path).readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const fileExtension = 'jpg';
    final fileName = 'avatar_${userId}_$timestamp.$fileExtension';

    await _supabase.storage.from('profiles').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    final publicUrl = _supabase.storage.from('profiles').getPublicUrl(fileName);

    await _supabase
        .from('perfiles')
        .update({'foto_url': publicUrl})
        .eq('usuario_id', userId);

    return publicUrl;
  }

  Future<void> _showBlockingLoader(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _closeBlockingLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
