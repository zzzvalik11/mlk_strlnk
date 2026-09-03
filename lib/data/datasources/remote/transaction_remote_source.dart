import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/transaction_model.dart';

/// Источник данных для истории транзакций.
/// Прокси к Starlink BSS (api.yaml v3.0.0).
class TransactionRemoteSource {
  final ApiClient _apiClient;

  TransactionRemoteSource({required this._apiClient});

  /// POST /v1/subscriber/accounts/{accountId}/transactions
  /// История транзакций с фильтрацией по датам.
  Future<List<TransactionModel>> getTransactionHistory({
    required int accountId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final body = <String, dynamic>{};
    if (dateFrom != null) body['date_from'] = dateFrom;
    if (dateTo != null) body['date_to'] = dateTo;
    final response = await _apiClient.post(
      '/v1/subscriber/accounts/$accountId/transactions',
      body: body,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
