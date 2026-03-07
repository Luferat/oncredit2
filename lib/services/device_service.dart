// lib/services/device_service.dart

import '../config/app_config.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _uuid = Uuid();

  static Future<String> getInitialId() async {
    final androidId = await AppConfig.getDeviceId();

    if (androidId.isNotEmpty) {
      return androidId;
    }

    return _uuid.v4();
  }

  static Future<String?> register({
    required String deviceId,
    required String apiUrl,
  }) async {
    final cleanedUrl = apiUrl.replaceAll(RegExp(r'/+$'), '');

    final online = await AppConfig.ping(customUrl: cleanedUrl);
    if (!online) {
      return 'Servidor indisponível.';
    }

    return await AppConfig.register(deviceId, customUrl: cleanedUrl);
  }
}
