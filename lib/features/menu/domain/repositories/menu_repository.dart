import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

abstract class MenuRepository {
  // Fetch items with optional ID-based filtering
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({
    int page,
    int pageSize,
    String? search,
    String? categoryId,
    List<String>? categoryIds,
    bool? isMostPopular,
    bool? isWeekendSpecial,
  });

  // Category Management
  Future<Either<Failure, List<Category>>> getMainCategories();
  Future<Either<Failure, List<Category>>> getSubCategories(String parentId);
  Future<Either<Failure, Category?>> getCategoryByName(String name);
  Future<Either<Failure, List<Category>>> getAllCategories();
  Future<Either<Failure, String>> createCategory(String name, {String? parentId});
  Future<Either<Failure, void>> updateCategory(String id, String newName);
  Future<Either<Failure, void>> deleteCategory(String id);

  // CRUD
  Future<Either<Failure, MenuItemEntity>> createMenuItem({required String name, String? description, required double price, String? categoryId, bool isAvailable = true, bool isMostPopular = false, bool isWeekendSpecial = false, String? imagePath, String? imageUrl});

  Future<Either<Failure, MenuItemEntity>> updateMenuItem({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, bool? isMostPopular, bool? isWeekendSpecial, String? imagePath, String? imageUrl});

  Future<Either<Failure, void>> deleteMenuItem(String id);

  // Favorites
  Future<Either<Failure, List<String>>> getFavorites();
  Future<Either<Failure, List<MenuItemEntity>>> getFavoriteItems();
  Future<Either<Failure, void>> toggleFavorite(String menuItemId);
}
