import 'dart:async';

/// A generic in-memory cache entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.ttl}) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Generic in-memory cache service with TTL and size limits
///
/// Usage:
/// ```dart
/// final cache = CacheService();
/// cache.set('menu_items', items, ttl: Duration(minutes: 5));
/// final items = cache.get<List<MenuItemEntity>>('menu_items');
/// ```
class CacheService {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final int maxEntries;
  Timer? _cleanupTimer;

  CacheService({this.maxEntries = 100}) {
    // Run cleanup every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) => _removeExpired());
  }

  /// Default TTL values for different cache types
  static const Duration shortTtl = Duration(minutes: 2);
  static const Duration mediumTtl = Duration(minutes: 5);
  static const Duration longTtl = Duration(minutes: 15);

  /// Get a cached value by key
  /// Returns null if not found or expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Set a value in cache with optional TTL
  void set<T>(String key, T data, {Duration ttl = mediumTtl}) {
    // Enforce max size by removing oldest entries
    if (_cache.length >= maxEntries) {
      _removeOldestEntries(maxEntries ~/ 4);
    }

    _cache[key] = CacheEntry<T>(data: data, ttl: ttl);
  }

  /// Check if a key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove a specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Remove all entries matching a key prefix
  /// Useful for invalidating related cache entries
  void removeByPrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Clear entries for a specific feature/domain
  void clearFeature(String featurePrefix) {
    _cache.removeWhere((key, _) => key.startsWith(featurePrefix));
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> get stats => {'entries': _cache.length, 'maxEntries': maxEntries, 'keys': _cache.keys.toList()};

  void _removeExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  void _removeOldestEntries(int count) {
    final entries = _cache.entries.toList()..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    for (var i = 0; i < count && i < entries.length; i++) {
      _cache.remove(entries[i].key);
    }
  }

  /// Dispose cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// Cache keys constants for type-safe cache access
abstract class CacheKeys {
  // Menu Feature
  static const String mainCategories = 'menu:main_categories';
  static String subCategories(String parentId) => 'menu:sub_categories:$parentId';
  static String menuItems(String categoryId) => 'menu:items:$categoryId';
  static const String popularItems = 'menu:popular_items';
  static const String specialItems = 'menu:special_items';

  // Auth Feature
  static const String userProfile = 'auth:user_profile';
  static const String userRole = 'auth:user_role';
}
