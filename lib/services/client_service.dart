// lib/services/client_service.dart

import 'package:dio/dio.dart';
import '../models/client.dart';
import '../models/client_list_response.dart';
import '../models/financial_event.dart';
import 'api_client.dart';

class ClientService {
  final Dio _dio = ApiClient.instance;

  Future<ClientListResponse> getClientList() async {
    final response = await _dio.get('/clients');
    return ClientListResponse.fromJson(response.data);
  }

  Future<Client> getClient(int id) async {
    final response = await _dio.get('/clients/$id');
    return Client.fromJson(response.data);
  }

  Future<int> createClient(Map<String, dynamic> data) async {
    final response = await _dio.post('/clients', data: data);
    return response.data['id'] as int;
  }

  Future<void> updateClient(int id, Map<String, dynamic> data) async {
    await _dio.put('/clients/$id', data: data);
  }

  Future<void> deleteClient(int id) async {
    await _dio.delete('/clients/$id');
  }

  Future<List<FinancialEvent>> getClientHistory(int id) async {
    final response = await _dio.get('/clients/$id/history');
    final list = response.data['history'] as List;
    return list.map((e) => FinancialEvent.fromJson(e)).toList();
  }

  Future<int> createPurchase(int clientId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/clients/$clientId/purchases',
      data: data,
    );
    return response.data['id'] as int;
  }

  Future<void> updatePurchase(
    int clientId,
    int purchaseId,
    Map<String, dynamic> data,
  ) async {
    await _dio.put('/clients/$clientId/purchases/$purchaseId', data: data);
  }

  Future<void> deletePurchase(int clientId, int purchaseId) async {
    await _dio.delete('/clients/$clientId/purchases/$purchaseId');
  }

  Future<int> createPayment(int clientId, Map<String, dynamic> data) async {
    final response = await _dio.post('/clients/$clientId/payments', data: data);
    return response.data['id'] as int;
  }

  Future<void> updatePayment(
    int clientId,
    int paymentId,
    Map<String, dynamic> data,
  ) async {
    await _dio.put('/clients/$clientId/payments/$paymentId', data: data);
  }

  Future<void> deletePayment(int clientId, int paymentId) async {
    await _dio.delete('/clients/$clientId/payments/$paymentId');
  }
}
