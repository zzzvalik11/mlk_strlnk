import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for key-value local storage.
/// Gracefully handles uninitialized state (e.g. web without proper config)
/// by returning null / false instead of throwing.
class StorageService {
  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Must be called once before using any other methods (e.g. in main.dart).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  // ─── String ─────────────────────────────────────
  String? getString(String key) => _prefs?.getString(key);
  Future<bool> setString(String key, String value) async {
    if (_prefs == null) return false;
    return _prefs!.setString(key, value);
  }

  // ─── Bool ──────────────────────────────────────
  bool? getBool(String key) => _prefs?.getBool(key);
  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) return false;
    return _prefs!.setBool(key, value);
  }

  // ─── Int ───────────────────────────────────────
  int? getInt(String key) => _prefs?.getInt(key);
  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) return false;
    return _prefs!.setInt(key, value);
  }

  // ─── Remove / Clear ────────────────────────────
  Future<bool> remove(String key) async {
    if (_prefs == null) return false;
    return _prefs!.remove(key);
  }
  Future<bool> clear() async {
    if (_prefs == null) return false;
    return _prefs!.clear();
  }
}
