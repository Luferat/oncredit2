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

  // Usado no GET /clients/<id>/purchases/<pur_id>
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as int,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitValue: (json['unit_value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Usado no POST e PUT
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_value': unitValue,
      'date': date.toIso8601String().substring(0, 19), // YYYY-MM-DDTHH:MM:SS
    };
  }
}
