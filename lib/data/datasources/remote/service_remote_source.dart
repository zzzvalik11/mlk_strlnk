import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/service_model.dart';

/// Источник данных для операций с услугами.
/// Прокси к Starlink BSS (api.yaml v3.0.0).
class ServiceRemoteSource {
  final ApiClient _apiClient;

  ServiceRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// GET /v1/subscriber/accounts/{accountId}/services
  /// Список услуг, подключённых к счёту.
  Future<List<ServiceModel>> getActiveServices({required int accountId}) async {
    final response = await _apiClient.get(
      '/v1/subscriber/accounts/$accountId/services',
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
