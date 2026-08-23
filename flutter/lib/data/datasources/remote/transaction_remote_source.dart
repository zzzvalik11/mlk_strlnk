import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/transaction_model.dart';

/// Remote data source for transaction-related API calls.
class TransactionRemoteSource {
  final ApiClient _apiClient;

  TransactionRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// `GET /transactions?page=&limit=` → list of transaction DTOs.
  Future<List<TransactionModel>> getTransactionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/transactions',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
