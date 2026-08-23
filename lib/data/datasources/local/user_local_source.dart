import 'dart:convert';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/data/models/user_model.dart';

/// Local data source for user session data persisted via [StorageService].
class UserLocalSource {
  static const String _userKey = 'telecom_user';

  final StorageService _storageService;

  UserLocalSource({required StorageService storageService})
      : _storageService = storageService;

  /// Persists the authentication [token].
  Future<bool> saveToken(String token) {
    return _storageService.setString(AppConstants.authTokenKey, token);
  }

  /// Retrieves the stored auth token, or null if not found.
  String? getToken() {
    return _storageService.getString(AppConstants.authTokenKey);
  }

  /// Removes the stored auth token.
  Future<bool> removeToken() {
    return _storageService.remove(AppConstants.authTokenKey);
  }

  /// Serialises [user] to JSON and stores it locally.
  Future<bool> saveUser(UserModel user) {
    final json = jsonEncode(user.toJson());
    return _storageService.setString(_userKey, json);
  }

  /// Deserialises and returns the cached [UserModel], or null.
  UserModel? getUser() {
    final raw = _storageService.getString(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clears both token and cached user (full logout).
  Future<void> clearSession() async {
    await removeToken();
    await _storageService.remove(_userKey);
  }
}
