import 'dart:convert';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/data/models/user_model.dart';

/// Auth method choices for quick re-login.
enum AuthMethod {
  pin,
  biometric,
}

/// Extension to parse [AuthMethod] from stored string.
extension AuthMethodX on AuthMethod {
  String get value => name;
}

/// Local data source for user session data persisted via [StorageService].
class UserLocalSource {
  static const String _userKey = 'telecom_user';

  final StorageService _storageService;

  UserLocalSource({required StorageService storageService})
      : _storageService = storageService;

  // ─── Token ─────────────────────────────────────
  Future<bool> saveToken(String token) {
    return _storageService.setString(AppConstants.authTokenKey, token);
  }

  String? getToken() {
    return _storageService.getString(AppConstants.authTokenKey);
  }

  Future<bool> removeToken() {
    return _storageService.remove(AppConstants.authTokenKey);
  }

  // ─── Token Expiry (365 days) ───────────────────
  Future<bool> saveTokenExpiry(DateTime expiry) {
    return _storageService.setInt(
      AppConstants.tokenExpiryKey,
      expiry.millisecondsSinceEpoch,
    );
  }

  DateTime? getTokenExpiry() {
    final ms = _storageService.getInt(AppConstants.tokenExpiryKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Returns true if the stored token has not expired.
  bool isTokenValid() {
    final expiry = getTokenExpiry();
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  // ─── User JSON ─────────────────────────────────
  Future<bool> saveUser(UserModel user) {
    final json = jsonEncode(user.toJson());
    return _storageService.setString(_userKey, json);
  }

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

  // ─── Auth Method (PIN or Biometric) ────────────
  Future<bool> saveAuthMethod(AuthMethod method) {
    return _storageService.setString(AppConstants.authMethodKey, method.value);
  }

  AuthMethod? getAuthMethod() {
    final raw = _storageService.getString(AppConstants.authMethodKey);
    if (raw == null) return null;
    return AuthMethod.values.firstWhere(
      (m) => m.value == raw,
      orElse: () => AuthMethod.pin,
    );
  }

  // ─── First Login Flag ──────────────────────────
  Future<bool> markFirstLoginDone() {
    return _storageService.setBool(AppConstants.firstLoginDoneKey, true);
  }

  bool isFirstLoginDone() {
    return _storageService.getBool(AppConstants.firstLoginDoneKey) ?? false;
  }

  // ─── Lock State ────────────────────────────────
  Future<bool> setLocked(bool locked) {
    return _storageService.setBool(AppConstants.isLockedKey, locked);
  }

  bool isLocked() {
    return _storageService.getBool(AppConstants.isLockedKey) ?? false;
  }

  // ─── Clear Session ─────────────────────────────
  Future<void> clearSession() async {
    await removeToken();
    await _storageService.remove(_userKey);
    await _storageService.remove(AppConstants.tokenExpiryKey);
    await _storageService.remove(AppConstants.authMethodKey);
    await _storageService.remove(AppConstants.firstLoginDoneKey);
    await _storageService.remove(AppConstants.isLockedKey);
  }
}
