// lib/services/update_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  // URL independente da API principal — aponta para onde você hospedar o JSON de update
  static const String _endpoint =
      'https://luferat.github.io/oncredit/latest_update.json';

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
    final date = parts[0].replaceAll('.', '');
    final build = parts.length > 1 ? parts[1] : '0';
    return int.parse('$date$build');
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    if (!_isSupportedPlatform) return null;

    try {
      final response = await Dio().get(
        _endpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      final latestVersion = data['version'];
      final apkUrl = data['link'];
      final force = data['force'] ?? false;

      if (latestVersion == null || apkUrl == null) return null;

      final currentVersion = await getCurrentVersion();

      if (parseVersion(latestVersion) > parseVersion(currentVersion)) {
        return UpdateInfo(version: latestVersion, apkUrl: apkUrl, force: force);
      }
    } catch (_) {}

    return null;
  }
}