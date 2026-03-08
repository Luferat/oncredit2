// lib/models/payment.dart

class Payment {
  final int? id;
  final double value;
  final String method;
  final DateTime date;

  Payment({
    this.id,
    required this.value,
    required this.method,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      value: (json['value'] as num).toDouble(),
      method: json['method'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'method': method,
      'date': date.toIso8601String().substring(0, 19),
    };
  }
}
