// lib/models/purchase.dart

class Purchase {
  final int? id;
  final String description;
  final int quantity;
  final double unitValue;
  final DateTime date;

  Purchase({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitValue,
    required this.date,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as int,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitValue: (json['unit_value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_value': unitValue,
      'date': date.toIso8601String().substring(0, 19),
    };
  }
}
