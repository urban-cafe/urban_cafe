import 'package:urban_cafe/domain/entities/menu_item.dart';

abstract class MenuRepository {
  // Fetch items with optional ID-based filtering
  Future<List<MenuItemEntity>> getMenuItems({
    int page,
    int pageSize,
    String? search,
    String? categoryId, // Now filters by UUID
    List<String>? categoryIds, // List of UUIDs
  });

  // Category Management
  Future<List<Map<String, dynamic>>> getMainCategories(); // Returns [{id, name}, ...]
  Future<List<Map<String, dynamic>>> getSubCategories(String parentId);
  Future<List<Map<String, dynamic>>> getAllCategories();
  Future<String> createCategory(String name, {String? parentId});
  Future<void> updateCategory(String id, String newName);
  Future<void> deleteCategory(String id);

  // CRUD
  Future<MenuItemEntity> createMenuItem({
    required String name,
    String? description,
    required double price,
    String? categoryId, // UUID
    bool isAvailable = true,
    bool isMostPopular = false,
    bool isWeekendSpecial = false,
    String? imagePath,
    String? imageUrl,
  });

  Future<MenuItemEntity> updateMenuItem({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, bool? isMostPopular, bool? isWeekendSpecial, String? imagePath, String? imageUrl});

  Future<void> deleteMenuItem(String id);
}
