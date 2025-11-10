import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Reproduce sonido de login exitoso (feedback háptico como botón flotante)
  Future<void> playLoginSound() async {
    try {
      // Feedback háptico satisfactorio como el botón flotante de Flutter
      await HapticFeedback.mediumImpact();
      // Pequeña pausa para efecto
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('Error en sonido de login: $e');
    }
  }

  /// Reproduce sonido de logout (feedback háptico suave)
  Future<void> playLogoutSound() async {
    try {
      // Feedback háptico suave para logout
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.selectionClick();
    } catch (e) {
      print('Error en sonido de logout: $e');
    }
  }

  /// Reproduce sonido de éxito
  Future<void> playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Reproduce sonido de error
  Future<void> playErrorSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Limpia recursos
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
