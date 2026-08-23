import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/balance_model.dart';

/// Remote data source for balance-related API calls.
class BalanceRemoteSource {
  final ApiClient _apiClient;

  BalanceRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// `GET /account/profile` → extracts and returns the `balance` object.
  Future<BalanceModel> getBalance() async {
    final response = await _apiClient.get('/account/profile');
    final data = response.data as Map<String, dynamic>;
    return BalanceModel.fromJson(data['balance'] as Map<String, dynamic>);
  }

  /// `POST /top-up` → returns a map with `newBalance`.
  Future<Map<String, dynamic>> topUp(double amount) async {
    final response = await _apiClient.post(
      '/top-up',
      body: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }
}
