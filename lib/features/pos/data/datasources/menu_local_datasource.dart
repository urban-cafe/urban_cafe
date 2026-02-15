import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

/// Local SQLite datasource for offline menu data caching.
class MenuLocalDatasource {
  static const String _dbName = 'urban_cafe_menu.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category_id TEXT,
        category_name TEXT,
        image_path TEXT,
        image_url TEXT,
        is_available INTEGER DEFAULT 1,
        is_most_popular INTEGER DEFAULT 0,
        is_weekend_special INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_item_variants (
        id TEXT PRIMARY KEY,
        menu_item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price_adjustment REAL DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_item_addons (
        id TEXT PRIMARY KEY,
        menu_item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL DEFAULT 0,
        FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ─── Write Operations ──────────────────────────────────────────

  /// Save all menu items with their variants and addons (replaces existing data).
  Future<void> saveAllItems(List<MenuItemEntity> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('menu_item_addons');
      await txn.delete('menu_item_variants');
      await txn.delete('menu_items');

      for (final item in items) {
        await txn.insert('menu_items', {
          'id': item.id,
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'category_id': item.categoryId,
          'category_name': item.categoryName,
          'image_path': item.imagePath,
          'image_url': item.imageUrl,
          'is_available': item.isAvailable ? 1 : 0,
          'is_most_popular': item.isMostPopular ? 1 : 0,
          'is_weekend_special': item.isWeekendSpecial ? 1 : 0,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final variant in item.variants) {
          await txn.insert('menu_item_variants', {
            'id': variant.id,
            'menu_item_id': item.id,
            'name': variant.name,
            'price_adjustment': variant.priceAdjustment,
            'is_default': variant.isDefault ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final addon in item.addons) {
          await txn.insert('menu_item_addons', {'id': addon.id, 'menu_item_id': item.id, 'name': addon.name, 'price': addon.price}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Save all categories.
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      for (final cat in categories) {
        await txn.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ─── Read Operations ───────────────────────────────────────────

  /// Get all menu items with variants and addons from local DB.
  Future<List<MenuItemEntity>> getAllItems() async {
    final db = await database;
    final itemRows = await db.query('menu_items', orderBy: 'name ASC');

    if (itemRows.isEmpty) return [];

    final variantRows = await db.query('menu_item_variants');
    final addonRows = await db.query('menu_item_addons');

    // Group variants and addons by menu_item_id
    final variantMap = <String, List<MenuItemVariant>>{};
    for (final v in variantRows) {
      final menuItemId = v['menu_item_id'] as String;
      variantMap
          .putIfAbsent(menuItemId, () => [])
          .add(MenuItemVariant(id: v['id'] as String, name: v['name'] as String, priceAdjustment: (v['price_adjustment'] as num).toDouble(), isDefault: v['is_default'] == 1));
    }

    final addonMap = <String, List<MenuItemAddon>>{};
    for (final a in addonRows) {
      final menuItemId = a['menu_item_id'] as String;
      addonMap.putIfAbsent(menuItemId, () => []).add(MenuItemAddon(id: a['id'] as String, name: a['name'] as String, price: (a['price'] as num).toDouble()));
    }

    return itemRows.map((row) {
      final id = row['id'] as String;
      return MenuItemEntity(
        id: id,
        name: row['name'] as String,
        description: row['description'] as String?,
        price: (row['price'] as num).toDouble(),
        categoryId: row['category_id'] as String?,
        categoryName: row['category_name'] as String?,
        imagePath: row['image_path'] as String?,
        imageUrl: row['image_url'] as String?,
        isAvailable: row['is_available'] == 1,
        isMostPopular: row['is_most_popular'] == 1,
        isWeekendSpecial: row['is_weekend_special'] == 1,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        variants: variantMap[id] ?? [],
        addons: addonMap[id] ?? [],
      );
    }).toList();
  }

  /// Get all locally cached categories.
  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => Category(id: r['id'] as String, name: r['name'] as String)).toList();
  }

  /// Get count of cached menu items.
  Future<int> getItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM menu_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Sync Metadata ────────────────────────────────────────────

  /// Get the last sync timestamp.
  Future<DateTime?> getLastSyncTime() async {
    final db = await database;
    final result = await db.query('sync_metadata', where: "key = ?", whereArgs: ['last_sync_time']);
    if (result.isEmpty) return null;
    return DateTime.tryParse(result.first['value'] as String);
  }

  /// Set the last sync timestamp.
  Future<void> setLastSyncTime(DateTime time) async {
    final db = await database;
    await db.insert('sync_metadata', {'key': 'last_sync_time', 'value': time.toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Cleanup ───────────────────────────────────────────────────

  /// Clear all locally cached data (for logout).
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('menu_item_addons');
      await txn.delete('menu_item_variants');
      await txn.delete('menu_items');
      await txn.delete('categories');
      await txn.delete('sync_metadata');
    });
  }

  /// Close database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
