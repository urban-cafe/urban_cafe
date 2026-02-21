import 'package:flutter/foundation.dart' hide Category;
import 'package:sqlite3/common.dart';
import 'package:urban_cafe/core/services/menu_cache_database_native.dart' if (dart.library.html) 'package:urban_cafe/core/services/menu_cache_database_web.dart' as platform;
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

/// Persistent SQLite cache for menu items and categories.
///
/// Works on **all platforms**: native uses FFI, web uses WASM + IndexedDB.
class MenuCacheDatabase {
  CommonDatabase? _db;

  /// Whether the database is operational.
  bool get isAvailable => _db != null;

  // ── Initialization ──────────────────────────────────────────────

  Future<void> init() async {
    try {
      _db = await platform.openMenuCacheDb();
      _createTables();
      debugPrint('[MenuCache] SQLite initialized successfully');
    } catch (e) {
      debugPrint('[MenuCache] Failed to init SQLite: $e');
    }
  }

  void _createTables() {
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS cached_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT
      )
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS cached_menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category_id TEXT,
        category_name TEXT,
        image_path TEXT,
        image_url TEXT,
        is_available INTEGER NOT NULL DEFAULT 1,
        is_most_popular INTEGER NOT NULL DEFAULT 0,
        is_weekend_special INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS cached_variants_addons (
        id TEXT PRIMARY KEY,
        menu_item_id TEXT NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        price_adjustment REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes for common queries
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_menu_category ON cached_menu_items(category_id)');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_menu_popular ON cached_menu_items(is_most_popular)');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_menu_special ON cached_menu_items(is_weekend_special)');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_va_item ON cached_variants_addons(menu_item_id)');
  }

  // ── Categories ──────────────────────────────────────────────────

  void upsertCategories(List<Category> categories, {String? parentId}) {
    if (!isAvailable) return;
    _db!.execute('BEGIN');
    try {
      final stmt = _db!.prepare('INSERT OR REPLACE INTO cached_categories (id, name, parent_id) VALUES (?, ?, ?)');
      for (final cat in categories) {
        stmt.execute([cat.id, cat.name, parentId]);
      }
      stmt.close();
      _db!.execute('COMMIT');
    } catch (e) {
      _db!.execute('ROLLBACK');
      rethrow;
    }
  }

  List<Category> getCategories({String? parentId}) {
    if (!isAvailable) return [];
    final ResultSet rows;
    if (parentId == null) {
      rows = _db!.select('SELECT id, name FROM cached_categories WHERE parent_id IS NULL');
    } else {
      rows = _db!.select('SELECT id, name FROM cached_categories WHERE parent_id = ?', [parentId]);
    }
    return rows.map((r) => Category(id: r['id'] as String, name: r['name'] as String)).toList();
  }

  // ── Menu Items ──────────────────────────────────────────────────

  void upsertMenuItems(List<MenuItemEntity> items) {
    if (!isAvailable) return;
    _db!.execute('BEGIN');
    try {
      final itemStmt = _db!.prepare('''
        INSERT OR REPLACE INTO cached_menu_items 
        (id, name, description, price, category_id, category_name, image_path, image_url, 
         is_available, is_most_popular, is_weekend_special, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      final deleteVaStmt = _db!.prepare('DELETE FROM cached_variants_addons WHERE menu_item_id = ?');
      final vaStmt = _db!.prepare('''
        INSERT INTO cached_variants_addons 
        (id, menu_item_id, type, name, price_adjustment, price, is_default)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''');

      for (final item in items) {
        itemStmt.execute([
          item.id,
          item.name,
          item.description,
          item.price,
          item.categoryId,
          item.categoryName,
          item.imagePath,
          item.imageUrl,
          item.isAvailable ? 1 : 0,
          item.isMostPopular ? 1 : 0,
          item.isWeekendSpecial ? 1 : 0,
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
        ]);

        deleteVaStmt.execute([item.id]);

        for (final v in item.variants) {
          vaStmt.execute([v.id, item.id, 'variant', v.name, v.priceAdjustment, 0, v.isDefault ? 1 : 0]);
        }
        for (final a in item.addons) {
          vaStmt.execute([a.id, item.id, 'addon', a.name, 0, a.price, 0]);
        }
      }

      itemStmt.close();
      deleteVaStmt.close();
      vaStmt.close();
      _db!.execute('COMMIT');
    } catch (e) {
      _db!.execute('ROLLBACK');
      rethrow;
    }
  }

  List<MenuItemEntity> getMenuItems({String? categoryId, List<String>? categoryIds, String? search, bool? isMostPopular, bool? isWeekendSpecial, int page = 1, int pageSize = 10}) {
    if (!isAvailable) return [];

    final whereClauses = <String>[];
    final params = <Object?>[];

    if (categoryIds != null && categoryIds.isNotEmpty) {
      whereClauses.add('category_id IN (${List.filled(categoryIds.length, '?').join(',')})');
      params.addAll(categoryIds);
    } else if (categoryId != null) {
      whereClauses.add('category_id = ?');
      params.add(categoryId);
    }

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('name LIKE ?');
      params.add('%$search%');
    }

    if (isMostPopular == true) {
      whereClauses.add('is_most_popular = 1');
    }
    if (isWeekendSpecial == true) {
      whereClauses.add('is_weekend_special = 1');
    }

    final whereClause = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';
    final offset = (page - 1) * pageSize;

    final rows = _db!.select('SELECT * FROM cached_menu_items $whereClause ORDER BY name ASC LIMIT ? OFFSET ?', [...params, pageSize, offset]);

    if (rows.isEmpty) return [];

    // Batch-fetch variants/addons for all returned items
    final itemIds = rows.map((r) => r['id'] as String).toList();
    final vaRows = _db!.select('SELECT * FROM cached_variants_addons WHERE menu_item_id IN (${List.filled(itemIds.length, '?').join(',')})', itemIds);

    // Group by menu_item_id
    final vaMap = <String, List<Row>>{};
    for (final va in vaRows) {
      (vaMap[va['menu_item_id'] as String] ??= []).add(va);
    }

    return rows.map((r) {
      final id = r['id'] as String;
      final vas = vaMap[id] ?? [];

      return MenuItemEntity(
        id: id,
        name: r['name'] as String,
        description: r['description'] as String?,
        price: (r['price'] as num).toDouble(),
        categoryId: r['category_id'] as String?,
        categoryName: r['category_name'] as String?,
        imagePath: r['image_path'] as String?,
        imageUrl: r['image_url'] as String?,
        isAvailable: (r['is_available'] as int) == 1,
        isMostPopular: (r['is_most_popular'] as int) == 1,
        isWeekendSpecial: (r['is_weekend_special'] as int) == 1,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
        variants: vas
            .where((v) => v['type'] == 'variant')
            .map((v) => MenuItemVariant(id: v['id'] as String, name: v['name'] as String, priceAdjustment: (v['price_adjustment'] as num).toDouble(), isDefault: (v['is_default'] as int) == 1))
            .toList(),
        addons: vas.where((v) => v['type'] == 'addon').map((v) => MenuItemAddon(id: v['id'] as String, name: v['name'] as String, price: (v['price'] as num).toDouble())).toList(),
      );
    }).toList();
  }

  void deleteMenuItem(String id) {
    if (!isAvailable) return;
    _db!.execute('DELETE FROM cached_variants_addons WHERE menu_item_id = ?', [id]);
    _db!.execute('DELETE FROM cached_menu_items WHERE id = ?', [id]);
  }

  // ── Sync Metadata ───────────────────────────────────────────────

  String? getSyncValue(String key) {
    if (!isAvailable) return null;
    final rows = _db!.select('SELECT value FROM sync_metadata WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void setSyncValue(String key, String value) {
    if (!isAvailable) return;
    _db!.execute('INSERT OR REPLACE INTO sync_metadata (key, value) VALUES (?, ?)', [key, value]);
  }

  DateTime? getLastSyncTime() {
    final v = getSyncValue('last_sync_time');
    return v == null ? null : DateTime.tryParse(v);
  }

  void setLastSyncTime(DateTime time) {
    setSyncValue('last_sync_time', time.toIso8601String());
  }

  String? getMaxUpdatedAt() => getSyncValue('menu_max_updated_at');

  void setMaxUpdatedAt(String value) => setSyncValue('menu_max_updated_at', value);

  // ── Utilities ───────────────────────────────────────────────────

  bool hasCachedData() {
    if (!isAvailable) return false;
    final rows = _db!.select('SELECT COUNT(*) AS cnt FROM cached_menu_items');
    return (rows.first['cnt'] as int) > 0;
  }

  void clearAll() {
    if (!isAvailable) return;
    _db!.execute('DELETE FROM cached_variants_addons');
    _db!.execute('DELETE FROM cached_menu_items');
    _db!.execute('DELETE FROM cached_categories');
    _db!.execute('DELETE FROM sync_metadata');
  }

  void close() {
    _db?.close();
    _db = null;
  }
}
