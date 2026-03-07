// lib/services/update_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';

class UpdateInfo {
  final String version;
  final String apkUrl;
  final bool force;

  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.force,
  });
}

class UpdateService {
  static String get _endpoint => '${AppConfig.apiBaseUrl}/update';

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.isEmpty ? '0' : info.buildNumber;
    return '${info.version}+$build';
  }

  static int parseVersion(String version) {
    final parts = version.split('+');
    final date = int.parse(parts[0].replaceAll('.', ''));
    final build = parts.length > 1 ? int.parse(parts[1]) : 0;
    return date * 1000 + build;
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    if (!_isSupportedPlatform) return null;

    try {
      final currentVersion = await getCurrentVersion();

      final response = await Dio().get(
        _endpoint,
        options: Options(
          headers: {'X-API-Key': AppConfig.token},
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      final latestVersion = data['version'] as String;
      final apkUrl = data['apk'] as String;
      final force = (data['force'] as bool?) ?? false;

      if (parseVersion(latestVersion) > parseVersion(currentVersion)) {
        return UpdateInfo(version: latestVersion, apkUrl: apkUrl, force: force);
      }
    } catch (e) {
      debugPrint('UpdateService error: $e');
    }

    return null;
  }
}
