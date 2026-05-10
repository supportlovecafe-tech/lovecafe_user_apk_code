import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _menuPrefix = 'ce_menu_cache_';
  static const Duration _defaultTTL = Duration(minutes: 10);

  Future<void> cacheMenu(String cinemaId, List<dynamic> menuData) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheEntry = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': menuData,
    };
    await prefs.setString('${_menuPrefix}$cinemaId', jsonEncode(cacheEntry));
  }

  Future<List<dynamic>?> getCachedMenu(String cinemaId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('${_menuPrefix}$cinemaId');
    if (cached == null) return null;

    try {
      final decoded = jsonDecode(cached);
      return decoded['data'] as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isCacheStale(String cinemaId, [Duration ttl = _defaultTTL]) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('${_menuPrefix}$cinemaId');
    if (cached == null) return true;

    try {
      final decoded = jsonDecode(cached);
      final timestamp = decoded['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cachedTime) > ttl;
    } catch (e) {
      return true;
    }
  }

  Future<void> invalidateCache(String cinemaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_menuPrefix}$cinemaId');
  }
}

final cacheService = CacheService();
