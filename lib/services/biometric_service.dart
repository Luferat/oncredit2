// lib/services/biometric_service.dart

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _prefKey = 'biometric_enabled';
  static final _auth = LocalAuthentication();

  // Só disponível no Android (não na Web)
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  // Verifica se o dispositivo tem biometria disponível
  static Future<bool> isAvailable() async {
    if (!isSupported) return false;
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }

  // Realiza a autenticação
  static Future<bool> authenticate() async {
    if (!isSupported) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o ONCredit',
        options: const AuthenticationOptions(
          biometricOnly: false, // permite PIN como fallback
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
}
