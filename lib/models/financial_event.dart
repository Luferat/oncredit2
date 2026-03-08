// lib/models/financial_event.dart

enum FinancialEventType { purchase, payment }

class FinancialEvent {
  final int id;
  final String description;
  final double value;
  final DateTime date;
  final FinancialEventType type;
  final String? method;

  FinancialEvent({
    required this.id,
    required this.description,
    required this.value,
    required this.date,
    required this.type,
    this.method,
  });

  factory FinancialEvent.fromJson(Map<String, dynamic> json) {
    return FinancialEvent(
      id: json['id'] as int,
      description: json['description'] as String,
      value: (json['value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] == 'purchase'
          ? FinancialEventType.purchase
          : FinancialEventType.payment,
      method: json['method'] as String?,
    );
  }
}
