import 'package:urban_cafe/domain/entities/menu_item.dart';

abstract class MenuRepository {
  Future<List<MenuItemEntity>> getMenuItems({int page, int pageSize, String? search, String? category, List<String>? categories});

  Future<List<String>> getCategories();
  Future<List<String>> getMainCategories();
  Future<List<String>> getSubCategories(String parentName);

  Future<MenuItemEntity> createMenuItem({required String name, String? description, required double price, String? category, bool isAvailable = true, String? imagePath, String? imageUrl});

  Future<MenuItemEntity> updateMenuItem({required String id, String? name, String? description, double? price, String? category, bool? isAvailable, String? imagePath, String? imageUrl});

  Future<void> deleteMenuItem(String id);
}
