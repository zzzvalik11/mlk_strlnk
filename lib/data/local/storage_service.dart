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

  /// Reads a string value for [key], or null if not found.
  String? getString(String key) {
    return _instance.getString(key);
  }

  /// Persists a string [value] under [key].
  Future<bool> setString(String key, String value) {
    return _instance.setString(key, value);
  }

  /// Removes the value stored under [key].
  Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  /// Clears all entries from local storage.
  Future<bool> clear() {
    return _instance.clear();
  }
}
