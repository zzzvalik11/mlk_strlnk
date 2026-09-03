import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';

/// Источник данных для операций со счетами абонента.
/// Прокси к Starlink BSS (api.yaml v3.0.0).
class BalanceRemoteSource {
  final ApiClient _apiClient;

  BalanceRemoteSource({required this._apiClient});

  /// GET /v1/subscriber/accounts — список лицевых счетов.
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final response = await _apiClient.get('/v1/subscriber/accounts');
    final data = response.data as List<dynamic>;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// GET /v1/subscriber/accounts/{id} — конкретный счёт.
  Future<Map<String, dynamic>> getAccountById(int accountId) async {
    final response = await _apiClient.get('/v1/subscriber/accounts/$accountId');
    return response.data as Map<String, dynamic>;
  }

  /// GET /v1/resources/promised-pay-terms — условия обещанного платежа.
  Future<Map<String, dynamic>> getPromisedPayTerms() async {
    final response = await _apiClient.get('/v1/resources/promised-pay-terms');
    return response.data as Map<String, dynamic>;
  }
}
