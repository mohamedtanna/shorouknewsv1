import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _prefix = 'cache_';
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() => _instance;
  CacheManager._internal();

  Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('$_prefix$key');
    if (data == null) return null;
    try {
      return jsonDecode(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(value));
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  Future<void> removeExpired({Duration expiration = const Duration(hours: 24)}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      final String? data = prefs.getString(key);
      if (data == null) continue;
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map && decoded['timestamp'] != null) {
          final ts = DateTime.tryParse(decoded['timestamp'].toString());
          if (ts == null || now.difference(ts) > expiration) {
            await prefs.remove(key);
          }
        }
      } catch (_) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
