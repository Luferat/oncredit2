import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../services/biometric_service.dart';
import 'device_register_dialog.dart';

class StartupService {

  static Future<void> run(BuildContext context) async {

    final online = await AppConfig.ping();

    if (!online) {
      await _showServerError(context);
      SystemNavigator.pop();
      return;
    }

    final hasToken = await AppConfig.hasToken();

    if (!hasToken) {

      final registered = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DeviceRegisterDialog(),
      );

      if (registered != true) {
        SystemNavigator.pop();
        return;
      }
    }

    final biometricEnabled = await BiometricService.isEnabled();

    if (biometricEnabled) {
      final auth = await BiometricService.authenticate();

      if (!auth) {
        SystemNavigator.pop();
        return;
      }
    }

    if (!context.mounted) return;

    Navigator.pushReplacementNamed(context, '/clients');
  }

  static Future<void> _showServerError(BuildContext context) async {

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Servidor indisponível'),
        content: const Text('Não foi possível conectar à API.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          )
        ],
      ),
    );
  }
}