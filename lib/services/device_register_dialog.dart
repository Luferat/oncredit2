// lib/services/device_register_dialog.dart

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/device_service.dart';

class DeviceRegisterDialog extends StatefulWidget {
  const DeviceRegisterDialog({super.key});

  @override
  State<DeviceRegisterDialog> createState() => _DeviceRegisterDialogState();
}

class _DeviceRegisterDialogState extends State<DeviceRegisterDialog> {
  final uidController = TextEditingController();
  final urlController = TextEditingController(text: AppConfig.apiBaseUrl);

  String? uidError;
  String? urlError;

  @override
  void initState() {
    super.initState();
    DeviceService.getInitialId().then((id) {
      uidController.text = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bem-vindo ao ONCredit'),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: uidController,
            decoration: InputDecoration(
              labelText: 'ID do dispositivo',
              errorText: uidError,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'URL da API',
              errorText: urlError,
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),

        ElevatedButton(onPressed: _confirm, child: const Text('Confirmar')),
      ],
    );
  }

  Future<void> _confirm() async {
    final uid = uidController.text.trim();
    final url = urlController.text.trim();

    if (uid.isEmpty) {
      setState(() => uidError = 'Informe o ID');
      return;
    }

    if (url.isEmpty) {
      setState(() => urlError = 'Informe a URL');
      return;
    }

    final error = await DeviceService.register(deviceId: uid, apiUrl: url);

    if (error != null) {
      setState(() => uidError = error);
      return;
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }
}
