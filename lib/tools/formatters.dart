// lib/tools/formatters.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final dateFormat = DateFormat('dd/MM/yyyy');
  static final dateTimeFormat = DateFormat(
    'dd/MM/yyyy HH:mm',
  );

  static final currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  // Parseia datas ISO 8601 da API ("2026-03-05T13:49:02")
  static DateTime parseDate(String value) {
    return DateTime.parse(value);
  }

  // Formata DateTime para exibição (sem hora) — uso geral no histórico
  static String formatDate(DateTime date) => dateFormat.format(date);

  // Formata DateTime com hora — reservado para quando necessário
  static String formatDateTime(DateTime date) => dateTimeFormat.format(date);

  static final currencyInput = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = double.parse(digits) / 100;
    final text = currencyFormat.format(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });

  static double parseCurrency(String text) {
    final clean = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static String formatPhone(String value) {
    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) '
          '${numbers.substring(2, 7)}-'
          '${numbers.substring(7)}';
    }
    if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) '
          '${numbers.substring(2, 6)}-'
          '${numbers.substring(6)}';
    }
    return value;
  }
}
