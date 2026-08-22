import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/service_model.dart';

/// Remote data source for service-related API calls.
class ServiceRemoteSource {
  final ApiClient _apiClient;

  ServiceRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// `GET /account/profile` → extracts the `activeServices` list.
  Future<List<ServiceModel>> getActiveServices() async {
    final response = await _apiClient.get('/account/profile');
    final data = response.data as Map<String, dynamic>;
    final servicesRaw = data['activeServices'] as List<dynamic>;
    return servicesRaw
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
