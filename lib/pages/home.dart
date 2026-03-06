// lib/pages/home.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../services/biometric_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    final hasToken = await AppConfig.hasToken();

    if (!mounted) return;

    if (!hasToken) {
      final configured = await _requestUid();
      if (!configured) {
        SystemNavigator.pop();
        return;
      }
    }

    if (!mounted) return;

    final biometricEnabled = await BiometricService.isEnabled();
    if (biometricEnabled) {
      setState(() => _showBiometric = true);
      final authenticated = await BiometricService.authenticate();
      if (!mounted) return;
      if (!authenticated) {
        SystemNavigator.pop();
        return;
      }
      setState(() => _showBiometric = false);
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/clients');
  }

  Future<bool> _requestUid() async {
    final deviceId = await AppConfig.getDeviceId();
    final uidController = TextEditingController(text: deviceId);
    final urlController = TextEditingController(text: AppConfig.apiBaseUrl);
    String? uidError;
    String? urlError;
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Bem-vindo ao ONCredit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Para começar, configure o acesso ao servidor.\n\n'
                          'Em caso de dúvidas, contacte o administrador do sistema.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: uidController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'ID do dispositivo',
                        border: const OutlineInputBorder(),
                        errorText: uidError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'URL da API',
                        border: const OutlineInputBorder(),
                        errorText: urlError,
                        helperText: 'Ex: http://192.168.1.10:5000/api',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final uid = uidController.text.trim();
                    final url = urlController.text
                        .trim()
                        .replaceAll(RegExp(r'/+$'), '');

                    // Validações básicas
                    if (uid.isEmpty) {
                      setDialogState(() {
                        uidError = 'Informe o ID';
                        urlError = null;
                      });
                      return;
                    }
                    if (url.isEmpty) {
                      setDialogState(() {
                        uidError = null;
                        urlError = 'Informe a URL da API';
                      });
                      return;
                    }

                    setDialogState(() {
                      uidError = null;
                      urlError = null;
                    });

                    final navigator = Navigator.of(dialogContext);

                    // Testa conectividade com a URL informada
                    final online = await AppConfig.ping(customUrl: url);
                    if (!online) {
                      setDialogState(() =>
                      urlError = 'Servidor indisponível. Verifique a URL.');
                      return;
                    }

                    // Registra passando a URL customizada
                    final error = await AppConfig.register(
                      uid,
                      customUrl: url,
                    );

                    if (error != null) {
                      setDialogState(() {
                        uidError = error;
                        urlError = null;
                      });
                      return;
                    }

                    confirmed = true;
                    navigator.pop();
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'ON',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 42,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.credit_score, color: Colors.white, size: 50),
                SizedBox(width: 4),
                Text(
                  'Credit',
                  style: TextStyle(color: Colors.white, fontSize: 36),
                ),
              ],
            ),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showBiometric
                  ? const Icon(
                Icons.fingerprint,
                key: ValueKey('fingerprint'),
                size: 72,
                color: Colors.orange,
              )
                  : const SizedBox(
                key: ValueKey('spinner'),
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _showBiometric ? 'Confirme sua identidade' : 'Aguarde...',
                key: ValueKey(_showBiometric),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}