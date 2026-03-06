// lib/services/api_client.dart

import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiClient {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final token = AppConfig.token;
              if (token.isNotEmpty) {
                options.headers['X-API-Key'] = token;
              }
              handler.next(options);
            },

            onError: (DioException error, handler) {
              final status = error.response?.statusCode;
              final message = _friendlyMessage(status, error);
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: ApiException(message: message, statusCode: status),
                  response: error.response,
                  type: error.type,
                ),
              );
            },
          ),
        );

  // static Dio get instance => _dio;

  static Dio get instance {
    _dio.options.baseUrl = AppConfig.apiBaseUrl; // ← atualiza antes de cada uso
    return _dio;
  }

  static String _friendlyMessage(int? status, DioException error) {
    switch (status) {
      case 400:
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      case 401:
        return 'Sessão expirada. Reinicie o aplicativo.';
      case 403:
        return 'Acesso negado. Dispositivo não autorizado.';
      case 404:
        return 'Registro não encontrado.';
      case 409:
        return 'CPF já cadastrado.';
      case 500:
        return 'Erro interno no servidor. Tente novamente mais tarde.';
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return 'Tempo de conexão esgotado. Verifique sua rede.';
        }
        if (error.type == DioExceptionType.connectionError) {
          return 'Sem conexão com o servidor. Verifique a URL da API.';
        }
        return 'Erro inesperado. Tente novamente.';
    }
  }
}

// Exceção tipada para capturar nos widgets
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
