import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class GetMenuItems {
  final MenuRepository repository;
  const GetMenuItems(this.repository);

  Future<List<MenuItemEntity>> call({int page = 1, int pageSize = 20, String? search, String? category, List<String>? categories}) {
    return repository.getMenuItems(page: page, pageSize: pageSize, search: search, category: category, categories: categories);
  }
}
