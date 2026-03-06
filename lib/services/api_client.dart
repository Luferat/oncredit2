// lib\services\api_client.dart

import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AppConfig.token;
        if (token.isNotEmpty) {
          options.headers['X-API-Key'] = token;
        }
        handler.next(options);
      },
    ),
  );

  static Dio get instance => _dio;
}