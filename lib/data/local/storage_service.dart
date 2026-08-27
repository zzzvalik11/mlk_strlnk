import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for key-value local storage.
/// On web, uses an in-memory [Map] to avoid platform plugin errors
/// (e.g. NotInitializedError from SharedPreferences web implementation).
class StorageService {
  SharedPreferences? _prefs;
  final Map<String, Object> _memory = {};
  bool _useMemory = false;

  /// Whether we are using the in-memory fallback.
  bool get isMemory => _useMemory;

  /// Must be called once before using any other methods (e.g. in main.dart).
  Future<void> init() async {
    if (kIsWeb) {
      // On web, always use in-memory storage to avoid
      // NotInitializedError from the shared_preferences web plugin.
      _useMemory = true;
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _useMemory = true;
    }
  }

  // ─── String ─────────────────────────────────────
  String? getString(String key) {
    if (_useMemory) {
      print('[STORE] getString($key) -> memory: ${_memory.containsKey(key)}');
      return _memory[key] as String?;
    }
    try {
      return _prefs?.getString(key);
    } catch (e) {
      print('[STORE] getString($key) EXCEPTION: $e');
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    if (_useMemory) {
      _memory[key] = value;
      return true;
    }
    try {
      return await _prefs?.setString(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Bool ──────────────────────────────────────
  bool? getBool(String key) {
    if (_useMemory) return _memory[key] as bool?;
    try {
      return _prefs?.getBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    if (_useMemory) {
      _memory[key] = value;
      return true;
    }
    try {
      return await _prefs?.setBool(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Int ───────────────────────────────────────
  int? getInt(String key) {
    if (_useMemory) return _memory[key] as int?;
    try {
      return _prefs?.getInt(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    if (_useMemory) {
      _memory[key] = value;
      return true;
    }
    try {
      return await _prefs?.setInt(key, value) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Remove / Clear ────────────────────────────
  Future<bool> remove(String key) async {
    if (_useMemory) {
      _memory.remove(key);
      return true;
    }
    try {
      return await _prefs?.remove(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    if (_useMemory) {
      _memory.clear();
      return true;
    }
    try {
      return await _prefs?.clear() ?? false;
    } catch (_) {
      return false;
    }
  }
}
