import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for key-value local storage.
class StorageService {
  SharedPreferences? _prefs;

  /// Must be called once before using any other methods (e.g. in main.dart).
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'StorageService not initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  // ─── String ─────────────────────────────────────
  String? getString(String key) => _instance.getString(key);
  Future<bool> setString(String key, String value) => _instance.setString(key, value);

  // ─── Bool ──────────────────────────────────────
  bool? getBool(String key) => _instance.getBool(key);
  Future<bool> setBool(String key, bool value) => _instance.setBool(key, value);

  // ─── Int ───────────────────────────────────────
  int? getInt(String key) => _instance.getInt(key);
  Future<bool> setInt(String key, int value) => _instance.setInt(key, value);

  // ─── Remove / Clear ────────────────────────────
  Future<bool> remove(String key) => _instance.remove(key);
  Future<bool> clear() => _instance.clear();
}
