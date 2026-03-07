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
    // Carrega configurações salvas (token, androidId, apiBaseUrl)
    await AppConfig.load();

    while (true) {
      if (!context.mounted) return;

      // ── 1. Testa conectividade ────────────────────────────────────────────
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
          // Abre formulário de configuração mesmo com API offline.
          // O usuário pode corrigir a URL e tentar registrar.
          // Se o registro falhar (API ainda offline), o erro aparece
          // dentro do próprio dialog — sem travar o app.
          if (!context.mounted) return;
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const DeviceRegisterDialog(),
          );
        }

        // 'retry' ou retorno do configure: volta ao topo e testa de novo
        continue;
      }

      // ── 2. API online — verifica se já temos token ────────────────────────
      final hasToken = await AppConfig.hasToken();

      if (!hasToken) {
        if (!context.mounted) return;

        final registered = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DeviceRegisterDialog(),
        );

        // Independente do resultado (ok ou cancelou), volta ao início:
        // se registrou com sucesso → ping confirma online e tem token → segue.
        // se cancelou → mostra o dialog de registro de novo.
        continue;
      }

      // ── 3. Tem token — verifica biometria ────────────────────────────────
      final biometricEnabled = await BiometricService.isEnabled();

      if (biometricEnabled) {
        if (!context.mounted) return;
        final auth = await BiometricService.authenticate();

        if (!auth) {
          // Biometria falhou ou cancelada: volta ao início do loop.
          // O usuário pode tentar de novo sem o app travar.
          continue;
        }
      }

      // ── 4. Tudo ok → vai para a lista de clientes ────────────────────────
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/clients');
      return;
    }
  }

  /// Retorna 'retry' (tentar novamente) ou 'configure' (abrir configurações).
  /// Nunca fecha o app — o usuário sempre tem uma saída.
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

    // Fallback: se o dialog for dispensado de alguma forma inesperada
    return result ?? 'retry';
  }
}