// lib/services/api_check_observer.dart
//
// Uso: registre em MaterialApp:
//
//   MaterialApp(
//     navigatorObservers: [ApiCheckObserver()],
//     ...
//   )
//
// Intercepta toda navegação e verifica se a API está online.
// Se offline, exibe dialog com opções — sem bloquear o app indefinidamente.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';

class ApiCheckObserver extends NavigatorObserver {
  // Rotas que gerenciam a própria conectividade (não checar duas vezes)
  static const _ignoredRoutes = {'/', '/home'};

  // Evita checagens simultâneas (ex: animação de transição dispara 2x)
  bool _checking = false;

  @override
  void didPush(Route route, Route? previousRoute) {
    _maybeCheck(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) _maybeCheck(newRoute);
  }

  void _maybeCheck(Route route) {
    final name = route.settings.name ?? '';

    // Dialogs abertos com showDialog() não têm nome — ignorar para não
    // interferir com o fluxo de startup e outros dialogs internos.
    if (name.isEmpty) return;

    if (_ignoredRoutes.contains(name)) return;
    if (_checking) return;

    // Executa após o frame para garantir que o context da rota está montado
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final ctx = navigator?.context;
    if (ctx == null || !ctx.mounted) return;

    _checking = true;

    try {
      final online = await AppConfig.ping();
      if (!online && ctx.mounted) {
        await _showOfflineDialog(ctx);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _showOfflineDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor indisponível'),
        content: const Text(
          'A conexão com a API foi perdida.\n'
              'Verifique sua rede e tente novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: const Text('Sair'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );

    if (action == 'exit') {
      if (kIsWeb) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
      return;
    }

    // 'retry': testa de novo — se ainda offline, mostra o dialog novamente
    if (action == 'retry' && context.mounted) {
      await _check();
    }
  }
}