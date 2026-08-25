import 'package:dio/dio.dart' hide Headers;
import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/user_model.dart';

/// Источник данных для операций с профилем абонента.
/// Прокси к Starlink BSS (api.yaml v3.0.0).
class UserRemoteSource {
  final ApiClient _apiClient;

  UserRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// GET /v1/subscriber — профиль авторизованного абонента.
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get('/v1/subscriber');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /v1/auth/token — авторизация по PIN и паролю → JWT.
  Future<Map<String, dynamic>> login({
    required String pin,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/v1/auth/token',
      body: {'pin': pin, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/logout — выход из системы.
  Future<void> logout() async {
    await _apiClient.post('/v1/auth/logout');
  }
}
