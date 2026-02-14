import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite datasource for offline POS order queuing.
class PosLocalDatasource {
  static const String _dbName = 'urban_cafe_pos.db';
  static const String _tableName = 'pending_orders';
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
      CREATE TABLE $_tableName (
        offline_id TEXT PRIMARY KEY,
        staff_id TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        cash_tendered REAL DEFAULT 0,
        change_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'completed',
        items_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  /// Insert a pending offline order.
  Future<void> insertPendingOrder({
    required String offlineId,
    required String staffId,
    required double totalAmount,
    required String paymentMethod,
    required double cashTendered,
    required double changeAmount,
    required List<Map<String, dynamic>> itemsJson,
    required DateTime createdAt,
  }) async {
    final db = await database;
    await db.insert(_tableName, {
      'offline_id': offlineId,
      'staff_id': staffId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'cash_tendered': cashTendered,
      'change_amount': changeAmount,
      'items_json': jsonEncode(itemsJson),
      'created_at': createdAt.toIso8601String(),
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all unsynced pending orders.
  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    final results = await db.query(_tableName, where: 'synced = ?', whereArgs: [0], orderBy: 'created_at ASC');
    return results.map((row) {
      final mutableRow = Map<String, dynamic>.from(row);
      mutableRow['items_json'] = jsonDecode(row['items_json'] as String);
      return mutableRow;
    }).toList();
  }

  /// Mark an order as synced.
  Future<void> markAsSynced(String offlineId) async {
    final db = await database;
    await db.update(_tableName, {'synced': 1}, where: 'offline_id = ?', whereArgs: [offlineId]);
  }

  /// Get count of pending (unsynced) orders.
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all synced orders (cleanup).
  Future<void> deleteSyncedOrders() async {
    final db = await database;
    await db.delete(_tableName, where: 'synced = ?', whereArgs: [1]);
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
