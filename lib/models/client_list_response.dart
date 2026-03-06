// lib\models\client_list_response.dart

import 'client.dart';

class ClientListResponse {
  final double balance;
  final List<Client> clients;

  ClientListResponse({required this.balance, required this.clients});

  factory ClientListResponse.fromJson(Map<String, dynamic> json) {
    return ClientListResponse(
      balance: (json['balance'] as num).toDouble(),
      clients: (json['clients'] as List)
          .map((c) => Client.fromJson(c))
          .toList(),
    );
  }
}