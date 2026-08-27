import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for key-value local storage.
/// On web, falls back to an in-memory map so that platform plugins
/// that throw NotInitializedError never crash the app.
class StorageService {
  SharedPreferences? _prefs;
  final Map<String, String> _memoryStore = {};
  bool _useMemory = false;

  /// Must be called once before using any other methods (e.g. in main.dart).
  Future<void> init() async {
    if (kIsWeb) {
      // On web, use in-memory store to avoid NotInitializedError from
      // shared_preferences when the web platform is not fully configured.
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
    if (_useMemory) return _memoryStore[key];
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    if (_useMemory) {
      _memoryStore[key] = value;
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
    if (_useMemory) {
      final v = _memoryStore[key];
      return v == 'true' ? true : v == 'false' ? false : null;
    }
    try {
      return _prefs?.getBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    if (_useMemory) {
      _memoryStore[key] = value.toString();
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
    if (_useMemory) {
      final v = _memoryStore[key];
      return v != null ? int.tryParse(v) : null;
    }
    try {
      return _prefs?.getInt(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    if (_useMemory) {
      _memoryStore[key] = value.toString();
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
      _memoryStore.remove(key);
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
      _memoryStore.clear();
      return true;
    }
    try {
      return await _prefs?.clear() ?? false;
    } catch (_) {
      return false;
    }
  }
}
