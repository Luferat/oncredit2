// lib/tools/api_error.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

/// Extrai a mensagem amigável de qualquer erro
String apiErrorMessage(Object error) {
  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  return 'Erro inesperado. Tente novamente.';
}

/// Exibe SnackBar vermelho com a mensagem do erro
void showApiError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(apiErrorMessage(error)),
      backgroundColor: Colors.red.shade700,
    ),
  );
}