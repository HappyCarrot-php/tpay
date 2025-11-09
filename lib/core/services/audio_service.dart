import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Reproduce sonido de login exitoso
  Future<void> playLoginSound() async {
    try {
      // Usar sonido del sistema (puedes cambiar por asset personalizado)
      await _audioPlayer.play(AssetSource('sounds/login.mp3'));
    } catch (e) {
      // Fallback a vibración si no hay sonido
      await HapticFeedback.mediumImpact();
    }
  }

  /// Reproduce sonido de logout
  Future<void> playLogoutSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/logout.mp3'));
    } catch (e) {
      await HapticFeedback.lightImpact();
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
