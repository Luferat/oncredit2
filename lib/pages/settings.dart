// lib/pages/settings.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../templates/appbar.dart';
import '../config/app_config.dart';
import '../theme/theme_extensions.dart';
import '../services/biometric_service.dart';
import '../services/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  bool _biometricEnabled = false; // ← novo
  bool _biometricAvailable = false; // ← novo

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadBiometric(); // ← novo
  }

  Future<void> _loadBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _editCriticalSettings() async {
    final uidController = TextEditingController(text: AppConfig.androidId);
    final urlController = TextEditingController(text: AppConfig.apiBaseUrl);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          '⚠ Configurações Críticas',
          style: TextStyle(color: Colors.red),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Alterar essas configurações pode impedir o funcionamento do app.\n\n'
                'Use apenas se souber o que está fazendo.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: uidController,
                decoration: const InputDecoration(
                  labelText: 'UID do dispositivo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL da API',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newUid = uidController.text.trim();
    final newUrl = urlController.text.trim().replaceAll(RegExp(r'/+$'), '');

    final unchanged =
        newUid == AppConfig.androidId && newUrl == AppConfig.apiBaseUrl;
    if (unchanged) return;

    final confirmed = await _confirmCriticalChange();
    if (!confirmed) return;

    final error = await AppConfig.register(newUid, customUrl: newUrl);

    if (!mounted) return;

    setState(() {}); // atualiza a exibição na seção Administração

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Configurações atualizadas com sucesso')),
    );
  }

  Future<bool> _confirmCriticalChange() async {
    final controller = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Text(
          '🚨 CONFIRMAÇÃO OBRIGATÓRIA',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Você está alterando parâmetros internos do sistema.\n\n'
              'Isso pode impedir o funcionamento do aplicativo.\n\n'
              'Digite CONFIRMAR para continuar.',
            ),
            const SizedBox(height: 16),
            TextField(controller: controller),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'CONFIRMAR') {
                confirmed = true;
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _sectionTitle('Aparência'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: themeController,
                builder: (_, _) => SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Modo Escuro'),
                  subtitle: const Text('Alternar entre tema claro e escuro'),
                  value: themeController.isDarkMode,
                  onChanged: (value) async {
                    await themeController.toggleTheme(value);
                  },
                ),
              ),
            ),

            if (BiometricService.isSupported && _biometricAvailable) ...[
              const SizedBox(height: 24),

              _sectionTitle('Segurança'),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Acesso com biometria'),
                  subtitle: const Text(
                    'Solicitar digital ou PIN ao abrir o app',
                  ),
                  value: _biometricEnabled,
                  onChanged: (value) async {
                    await BiometricService.setEnabled(value);
                    setState(() {
                      _biometricEnabled = value;
                    });
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            _sectionTitle('Sistema'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Versão'),
                    trailing: Text(
                      _appVersion,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.cloud),
                    title: const Text('Ambiente'),
                    trailing: Chip(
                      label: Text(
                        AppConfig.environment,
                        style: TextStyle(color: Colors.black),
                      ),
                      backgroundColor: AppConfig.environment == 'DEV'
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text('Plataforma'),
                    subtitle: Text(
                      Theme.of(context).platform.name.toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Projeto'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (AppConfig.showRepositoryLink) ...[
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Repositório'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openRepository,
                    ),

                    const Divider(height: 1),
                  ],

                  ListTile(
                    leading: const Icon(Icons.edit_document),
                    title: Text('Licença: ${AppConfig.about['licenseName']}'),
                    trailing: const Icon(Icons.visibility),
                    onTap: _showLicenseDialog,
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.handyman),
                    title: const Text('Suporte técnico'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openSupport,
                  ),

                  if (!kIsWeb) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.system_update_alt),
                      title: const Text('Verificar atualizações'),
                      onTap: _checkUpdate,
                    ),
                  ],

                  const Divider(height: 1),

                  AboutListTile(
                    icon: const Icon(Icons.info),
                    applicationName: AppConfig.about['appName'],
                    applicationVersion: _appVersion,
                    applicationLegalese: AppConfig.about['app'],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Administração'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('UID Atual'),
                    subtitle: Text(
                      AppConfig.androidId.isEmpty ? '—' : AppConfig.androidId,
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('URL da API'),
                    subtitle: Text(AppConfig.apiBaseUrl),
                  ),

                  if (AppConfig.showResetLink) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services),
                      title: const Text('Resetar Configurações Locais'),
                      subtitle: const Text('Limpa preferências salvas'),
                      onTap: _resetLocalSettings,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Zona de Risco', color: Colors.red),

            Card(
              color: context.colors.errorContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: context.colors.onErrorContainer,
                ),
                title: Text(
                  'Alterar Id do dispositivo',
                  style: TextStyle(color: context.colors.onErrorContainer),
                ),
                subtitle: Text(
                  'Isso pode comprometer o funcionamento do app',
                  style: TextStyle(color: context.colors.onErrorContainer),
                ),
                onTap: _editCriticalSettings,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static final String? _licenseText = AppConfig.about['licenseText'];

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  AppConfig.about['licenseName']!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(child: Text(_licenseText!)),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }

  Future<void> _openRepository() async {
    final uri = Uri.parse(AppConfig.about['codeRepository']!);
    await launchUrl(uri);
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse(AppConfig.about['supportLink']!);
    await launchUrl(uri);
  }

  Future<void> _resetLocalSettings() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '⚠ PERIGO!',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Isso apagará configurações locais e tema.\nTambém desconectará o aplicativo da base de dados, se esta foi modificada antes.\n\nContinuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await AppConfig.clearToken();
    await AppConfig.load();
    await themeController.loadTheme();
    await _loadBiometric();

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações resetadas')));
  }

  Future<void> _checkUpdate() async {
    // Mostra um loading enquanto consulta
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final update = await UpdateService.checkForUpdate();

    if (!mounted) return;
    Navigator.pop(context); // fecha o loading

    if (update == null) {
      // Sem atualização disponível
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tudo atualizado!'),
          content: Text(
            'Você já está usando a versão $_appVersion, que é a mais recente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Tem atualização — mostra instruções
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova versão disponível!'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versão disponível: ${update.version}'),
              Text('Versão atual: $_appVersion'),
              const SizedBox(height: 16),
              const Text(
                'Como instalar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Toque em "Baixar APK" abaixo.\n'
                '2. Aguarde o download no navegador.\n'
                '3. Abra o arquivo baixado.\n'
                '4. Toque em "Instalar".\n'
                '5. Se solicitado, toque em "Verificar app" → \n'
                'Instalar apps desconhecidos e permita para o seu navegador.\n'
                '6. Conclua a instalação normalmente.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Baixar APK'),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(update.apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o link'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
