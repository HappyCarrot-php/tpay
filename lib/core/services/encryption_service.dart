import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Encripta una contraseña usando SHA-256
  String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verifica si una contraseña coincide con su hash
  bool verifyPassword(String password, String hashedPassword) {
    final encryptedInput = encryptPassword(password);
    return encryptedInput == hashedPassword;
  }

  /// Genera un hash único para tokens o IDs
  String generateHash(String input) {
    final bytes = utf8.encode('${input}_${DateTime.now().millisecondsSinceEpoch}');
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
