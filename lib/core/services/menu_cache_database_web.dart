import 'package:sqlite3/wasm.dart';

/// Opens a WASM-based SQLite database for menu caching on web.
Future<CommonDatabase> openMenuCacheDb() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'urban_cafe');
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return sqlite.open('urban_cafe_menu_cache.db');
}
