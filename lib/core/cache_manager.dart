class CacheManager {
  final Map<String, Map<String, dynamic>> _cache = {};

  Future<Map<String, dynamic>?> get(String key) async {
    return _cache[key];
  }

  Future<void> set(String key, Map<String, dynamic> value) async {
    _cache[key] = value;
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  Future<void> clear() async {
    _cache.clear();
  }

  Future<void> removeExpired() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    _cache.forEach((key, value) {
      final timestamp = value['timestamp'];
      if (timestamp is String) {
        final ts = DateTime.tryParse(timestamp);
        if (ts != null && ts.isBefore(now)) {
          expiredKeys.add(key);
        }
      }
    });
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}
