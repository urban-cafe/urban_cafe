import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens a native SQLite database for menu caching.
///
/// Uses the app's documents directory for persistent storage.
Future<CommonDatabase> openMenuCacheDb() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'urban_cafe_menu_cache.db');
  return sqlite3.open(dbPath);
}
