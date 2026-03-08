// lib/services/startup_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../services/biometric_service.dart';
import 'device_register_dialog.dart';

class StartupService {
  static Future<void> run(BuildContext context) async {
    await AppConfig.load();
    while (true) {
      if (!context.mounted) return;
      final online = await AppConfig.ping();
      if (!online) {
        if (!context.mounted) return;
        final action = await _showServerOfflineDialog(context);
        if (action == 'exit') {
          if (kIsWeb) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
          return;
        }
        if (action == 'configure') {
          if (!context.mounted) return;
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const DeviceRegisterDialog(),
          );
        }
        continue;
      }
      final hasToken = await AppConfig.hasToken();
      if (!hasToken) {
        if (!context.mounted) return;
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DeviceRegisterDialog(),
        );
        continue;
      }
      final biometricEnabled = await BiometricService.isEnabled();
      if (biometricEnabled) {
        if (!context.mounted) return;
        final auth = await BiometricService.authenticate();
        if (!auth) continue;
      }
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/clients');
      return;
    }
  }

  static Future<String> _showServerOfflineDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor indisponível'),
        content: const Text(
          'Não foi possível conectar à API.\n'
          'Verifique sua conexão ou ajuste o endereço da API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: const Text('Sair'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'configure'),
            child: const Text('Configurar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );

    return result ?? 'retry';
  }
}
