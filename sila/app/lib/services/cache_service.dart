import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _boxName = 'sila_cache';
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> save(String key, dynamic data) async {
    try {
      await _box.put(key, {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static dynamic load(String key) {
    try {
      final entry = _box.get(key);
      if (entry == null) return null;
      return entry['data'];
    } catch (_) {
      return null;
    }
  }

  static DateTime? getTimestamp(String key) {
    try {
      final entry = _box.get(key);
      if (entry == null) return null;
      return DateTime.parse(entry['timestamp'] as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}