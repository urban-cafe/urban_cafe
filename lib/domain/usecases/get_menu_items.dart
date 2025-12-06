import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class GetMenuItems {
  final MenuRepository repository;
  const GetMenuItems(this.repository);

  // Updated parameters to match the new Repository signature
  Future<List<MenuItemEntity>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId, // Changed from 'category'
    List<String>? categoryIds, // Changed from 'categories'
  }) {
    return repository.getMenuItems(page: page, pageSize: pageSize, search: search, categoryId: categoryId, categoryIds: categoryIds);
  }
}
