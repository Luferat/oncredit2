// lib/services/device_service.dart

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class DeviceService {
  /// Retorna o Android ID no Android; string vazia na Web.
  /// Não gera UUID aleatório — o usuário decide o ID se necessário.
  static Future<String> getInitialId() async {
    if (kIsWeb) return '';
    return await AppConfig.getDeviceId();
  }

  static Future<String?> register({
    required String deviceId,
    required String apiUrl,
  }) async {
    final cleanedUrl = apiUrl.replaceAll(RegExp(r'/+$'), '');

    final online = await AppConfig.ping(customUrl: cleanedUrl);
    if (!online) {
      return 'Servidor indisponível. Verifique a URL e tente novamente.';
    }

    return await AppConfig.register(deviceId, customUrl: cleanedUrl);
  }
}