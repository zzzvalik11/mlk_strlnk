import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for key-value local storage.
/// Every method is wrapped in try-catch so that platform plugins
/// (e.g. shared_preferences web implementation) that throw
/// NotInitializedError never crash the app.
class StorageService {
  SharedPreferences? _prefs;

  /// Must be called once before using any other methods (e.g. in main.dart).
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  // ─── String ─────────────────────────────────────
  String? getString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs?.setString(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Bool ──────────────────────────────────────
  bool? getBool(String key) {
    try {
      return _prefs?.getBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs?.setBool(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Int ───────────────────────────────────────
  int? getInt(String key) {
    try {
      return _prefs?.getInt(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs?.setInt(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Remove / Clear ────────────────────────────
  Future<bool> remove(String key) async {
    try {
      return await _prefs?.remove(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await _prefs?.clear() ?? false;
    } catch (_) {
      return false;
    }
  }
}
