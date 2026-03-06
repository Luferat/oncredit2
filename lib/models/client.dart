// lib/models/client.dart

class ClientContact {
  final String type; // Fixo, Celular, E-mail
  final String value;

  ClientContact({required this.type, required this.value});

  factory ClientContact.fromJson(Map<String, dynamic> json) {
    return ClientContact(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'value': value};
}

class Client {
  final int id;
  final String name;
  final String cpf;

  // Preenchidos apenas no GET /clients/<id>
  final List<ClientContact> contacts;
  final double? totalPurchases;
  final double? totalPayments;
  final double? balance;

  Client({
    required this.id,
    required this.name,
    required this.cpf,
    this.contacts = const [],
    this.totalPurchases,
    this.totalPayments,
    this.balance,
  });

  // Telefones (Fixo + Celular) para exibição/ações
  List<String> get phones => contacts
      .where((c) => c.type == 'Celular' || c.type == 'Fixo')
      .map((c) => c.value)
      .toList();

  String get formattedCpf {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.'
        '${cpf.substring(3, 6)}.'
        '${cpf.substring(6, 9)}-'
        '${cpf.substring(9, 11)}';
  }

  // Usado no GET /clients (lista)
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      name: json['name'] as String,
      cpf: json['cpf'] as String,
      contacts: json['contacts'] != null
          ? (json['contacts'] as List)
              .map((c) => ClientContact.fromJson(c))
              .toList()
          : [],
      totalPurchases: (json['total_purchases'] as num?)?.toDouble(),
      totalPayments: (json['total_payments'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
    );
  }
}