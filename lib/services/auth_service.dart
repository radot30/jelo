import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';

  Future<bool> authenticateBiometric() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Silakan autentikasi untuk mengakses JELO',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Biometric auth error: $e');
      }
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<bool> validateCredentials(String email, String password) async {
    final savedEmail = await _storage.read(key: _keyEmail);
    final savedPassword = await _storage.read(key: _keyPassword);
    return savedEmail == email && savedPassword == password;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
