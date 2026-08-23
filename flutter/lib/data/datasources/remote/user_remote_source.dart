import 'package:dio/dio.dart' hide Headers;
import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/user_model.dart';

/// Remote data source for user-related API calls.
class UserRemoteSource {
  final ApiClient _apiClient;

  UserRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// `GET /account/profile` → parses the nested `user` object.
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get('/account/profile');
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// `POST /auth/login` → returns a map with `token` and `user`.
  Future<Map<String, dynamic>> login({
    required String pin,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'pin': pin, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }
}
