import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  LocalStorageHelper._();

  static SharedPreferences? _instance;

  /// Initialize SharedPreferences instance (call this at app startup)
  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get _prefs {
    if (_instance == null) {
      throw Exception(
        'LocalStorageHelper not initialized. Call LocalStorageHelper.init() at app startup.',
      );
    }
    return _instance!;
  }

  // ========================= Synchronous Operations =========================

  /// Retrieve a string value synchronously
  static String? getStringSync(String key) {
    return _prefs.getString(key);
  }

  /// Retrieve a boolean value synchronously with default
  static bool getBoolSync(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// Retrieve a list of strings synchronously
  static List<String>? getStringListSync(String key) {
    return _prefs.getStringList(key);
  }

  /// Retrieve an object synchronously from JSON string
  static T? getObjectSync<T>(
    String key, {
    required T Function(dynamic json) fromJson,
  }) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString);
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // ========================= String Operations =========================

  /// Store a string value
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  /// Retrieve a string value
  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  /// Get string with default value
  static Future<String> getStringOrDefault(String key, String defaultValue) async {
    return _prefs.getString(key) ?? defaultValue;
  }

  // ========================= Integer Operations =========================

  /// Store an integer value
  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  /// Retrieve an integer value
  static Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  /// Get int with default value
  static Future<int> getIntOrDefault(String key, int defaultValue) async {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // ========================= Double Operations =========================

  /// Store a double value
  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  /// Retrieve a double value
  static Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }

  /// Get double with default value
  static Future<double> getDoubleOrDefault(String key, double defaultValue) async {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // ========================= Boolean Operations =========================

  /// Store a boolean value
  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  /// Retrieve a boolean value
  static Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  /// Get bool with default value
  static Future<bool> getBoolOrDefault(String key, bool defaultValue) async {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // ========================= List Operations =========================

  /// Store a list of strings
  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  /// Retrieve a list of strings
  static Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }

  /// Get string list with default value
  static Future<List<String>> getStringListOrDefault(
    String key,
    List<String> defaultValue,
  ) async {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  // ========================= JSON/Object Operations =========================

  /// Store an object as JSON string
  static Future<bool> setObject(String key, dynamic object) {
    try {
      final jsonString = jsonEncode(object);
      return _prefs.setString(key, jsonString);
    } catch (e) {
      throw Exception('Failed to encode object: $e');
    }
  }

  /// Retrieve an object from JSON string
  static Future<T?> getObject<T>(
    String key, {
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString);
      return fromJson(json);
    } catch (e) {
      throw Exception('Failed to decode object: $e');
    }
  }

  /// Store a list of objects as JSON string
  static Future<bool> setObjectList(String key, List<dynamic> objects) {
    try {
      final jsonString = jsonEncode(objects);
      return _prefs.setString(key, jsonString);
    } catch (e) {
      throw Exception('Failed to encode object list: $e');
    }
  }

  /// Retrieve a list of objects from JSON string
  static Future<List<T>> getObjectList<T>(
    String key, {
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to decode object list: $e');
    }
  }

  // ========================= Key Management =========================

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }

  /// Remove a key-value pair
  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  /// Remove multiple keys
  static Future<bool> removeMultiple(List<String> keys) async {
    for (final key in keys) {
      await _prefs.remove(key);
    }
    return true;
  }

  /// Get all keys
  static Future<Set<String>> getAllKeys() async {
    return _prefs.getKeys();
  }

  /// Clear all data from SharedPreferences
  static Future<bool> clear() {
    return _prefs.clear();
  }

  // ========================= Utility Methods =========================

  /// Get the size of stored data (approximate)
  static Future<int> getSize(String key) async {
    final value = _prefs.getString(key) ?? _prefs.get(key).toString();
    return value.length;
  }

  /// Backup all data as JSON string
  static Future<String> backupAll() async {
    final keys = _prefs.getKeys();
    final backup = <String, dynamic>{};
    
    for (final key in keys) {
      backup[key] = _prefs.get(key);
    }
    
    return jsonEncode(backup);
  }

  /// Clear specific key pattern (e.g., all keys starting with "user_")
  static Future<bool> clearPattern(String pattern) async {
    final keys = _prefs.getKeys();
    final keysToRemove = keys.where((key) => key.startsWith(pattern)).toList();
    
    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
    
    return true;
  }
}
