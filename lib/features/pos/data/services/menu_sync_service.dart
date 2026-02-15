import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/features/menu/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/pos/data/datasources/menu_local_datasource.dart';
import 'package:urban_cafe/features/pos/data/datasources/pos_local_datasource.dart';

/// Orchestrates downloading menu data from Supabase and storing it locally.
class MenuSyncService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final MenuLocalDatasource _menuLocal;
  final PosLocalDatasource _posLocal;

  MenuSyncService({required SupabaseClient supabaseClient, required MenuLocalDatasource menuLocalDatasource, required PosLocalDatasource posLocalDatasource})
    : _supabase = supabaseClient,
      _menuLocal = menuLocalDatasource,
      _posLocal = posLocalDatasource;

  // ─── State ─────────────────────────────────────────────────────

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _error;
  String? get error => _error;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  int _cachedItemCount = 0;
  int get cachedItemCount => _cachedItemCount;

  double _progress = 0.0;
  double get progress => _progress;

  /// Human‐readable status text for the UI.
  String _syncStatus = '';
  String get syncStatus => _syncStatus;

  /// Image download progress (0‐based counters).
  int _totalImages = 0;
  int get totalImages => _totalImages;

  int _downloadedImages = 0;
  int get downloadedImages => _downloadedImages;

  // ─── Initialize (load cached metadata) ─────────────────────────

  Future<void> init() async {
    _lastSyncTime = await _menuLocal.getLastSyncTime();
    _cachedItemCount = await _menuLocal.getItemCount();
    notifyListeners();
  }

  // ─── Full Download ─────────────────────────────────────────────

  /// Download ALL menu items, categories, and images from Supabase
  /// and cache them locally. Returns `true` on success.
  Future<bool> downloadAllMenuData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _error = null;
    _progress = 0.0;
    _syncStatus = 'Preparing…';
    _downloadedImages = 0;
    _totalImages = 0;
    notifyListeners();

    try {
      // ── 1. Fetch categories ──────────────────────────────────
      _syncStatus = 'Downloading categories…';
      _progress = 0.05;
      notifyListeners();

      final catData = await _supabase.from('categories').select('id, name, parent_id').order('name', ascending: true);

      final categories = (catData as List<dynamic>).map((e) => {'id': e['id'] as String, 'name': e['name'] as String, 'parent_id': e['parent_id'] as String?}).toList();

      await _menuLocal.saveCategories(categories);

      _progress = 0.15;
      _syncStatus = 'Downloading menu items…';
      notifyListeners();

      // ── 2. Fetch all menu items (paginated) ──────────────────
      final allItems = <MenuItemEntity>[];
      const pageSize = 50;
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final data = await _supabase
            .from('menu_items')
            .select('*, categories(name), menu_item_variants(*), menu_item_addons(*)')
            .order('name', ascending: true)
            .range((page - 1) * pageSize, page * pageSize - 1);

        final items = (data as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();

        allItems.addAll(items);
        hasMore = items.length == pageSize;
        page++;

        // Update progress (0.15 → 0.45 for items)
        _progress = 0.15 + (0.30 * (allItems.length / (allItems.length + (hasMore ? pageSize : 0))));
        _syncStatus = 'Downloading menu items (${allItems.length})…';
        notifyListeners();
      }

      // ── 3. Store items locally ───────────────────────────────
      _progress = 0.45;
      _syncStatus = 'Saving menu data…';
      notifyListeners();

      await _menuLocal.saveAllItems(allItems);

      // ── 4. Download images ───────────────────────────────────
      final imageUrls = allItems
          .where((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty)
          .map((item) => item.imageUrl!)
          .toSet() // deduplicate
          .toList();

      _totalImages = imageUrls.length;
      _downloadedImages = 0;
      _syncStatus = 'Downloading images (0/$_totalImages)…';
      _progress = 0.50;
      notifyListeners();

      if (imageUrls.isNotEmpty) {
        await _downloadImagesInBatches(imageUrls);
      }

      // ── 5. Update sync metadata ──────────────────────────────
      final now = DateTime.now();
      await _menuLocal.setLastSyncTime(now);

      _lastSyncTime = now;
      _cachedItemCount = allItems.length;
      _progress = 1.0;
      _syncStatus = 'All done!';
      _isSyncing = false;
      notifyListeners();

      debugPrint(
        '[MenuSync] Downloaded ${allItems.length} items, '
        '${categories.length} categories, '
        '$_downloadedImages/$_totalImages images',
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _isSyncing = false;
      _progress = 0.0;
      _syncStatus = 'Failed: $_error';
      notifyListeners();
      debugPrint('[MenuSync] Error: $_error');
      return false;
    }
  }

  /// Download images in parallel batches for speed.
  Future<void> _downloadImagesInBatches(List<String> urls) async {
    const batchSize = 5;
    final cacheManager = DefaultCacheManager();

    for (int i = 0; i < urls.length; i += batchSize) {
      final batch = urls.sublist(i, (i + batchSize).clamp(0, urls.length));

      await Future.wait(
        batch.map((url) async {
          try {
            await cacheManager.downloadFile(url);
          } catch (e) {
            debugPrint('[MenuSync] Image cache failed: $url');
          }
          _downloadedImages++;
          _syncStatus = 'Downloading images ($_downloadedImages/$_totalImages)…';
          // Progress: 0.50 → 0.98 for images
          _progress = 0.50 + (0.48 * (_downloadedImages / _totalImages));
          notifyListeners();
        }),
      );
    }
  }

  // ─── Local Data Access ──────────────────────────────────────────

  /// Get all cached menu items.
  Future<List<MenuItemEntity>> getCachedItems() async {
    return _menuLocal.getAllItems();
  }

  /// Check if local cache has data.
  Future<bool> hasCachedData() async {
    final count = await _menuLocal.getItemCount();
    return count > 0;
  }

  // ─── Cleanup (Logout) ──────────────────────────────────────────

  /// Clear all local data (menu cache + POS pending orders + image cache).
  Future<void> clearAllLocalData() async {
    await _menuLocal.clearAll();
    await _posLocal.deleteSyncedOrders();

    // Clear pending orders on logout
    final db = await _posLocal.database;
    await db.delete('pending_orders');

    // Clear image cache
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('[MenuSync] Failed to clear image cache: $e');
    }

    _lastSyncTime = null;
    _cachedItemCount = 0;
    _progress = 0.0;
    _syncStatus = '';
    _downloadedImages = 0;
    _totalImages = 0;
    _error = null;
    notifyListeners();

    debugPrint('[MenuSync] Cleared all local data + image cache');
  }
}
