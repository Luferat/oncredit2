// lib/widgets/update_dialog.dart

import 'package:flutter/material.dart';
import '../services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo update;

  const UpdateDialog({
    super.key,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !update.force,
      child: AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Text(
          update.force
              ? 'Você precisa atualizar o aplicativo para continuar usando.'
              : 'Uma nova versão (${update.version}) está disponível.',
        ),
        actions: [
          if (!update.force)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Depois'),
            ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(update.apkUrl);
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}