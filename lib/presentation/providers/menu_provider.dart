import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class CategoryObj {
  final String id;
  final String name;
  CategoryObj(this.id, this.name);
}

class MenuProvider extends ChangeNotifier {
  final _repo = MenuRepositoryImpl();

  List<MenuItemEntity> items = [];
  List<CategoryObj> subCategories = [];

  bool loading = false;
  bool loadingMore = false;
  String? error;

  // Filters
  String? _currentCategoryId; // The selected sub-category ID
  List<String>? _currentCategoryIds; // List of IDs (e.g. all sub-cats of a main cat)
  String? _searchQuery;

  int _page = 1;
  final int _pageSize = 20;
  bool hasMore = true;

  // Initializer for the Menu Screen
  Future<void> initForMainCategory(String mainCategoryName) async {
    loading = true;
    notifyListeners();

    try {
      // 1. Find the ID of the Main Category (e.g. "HOT DRINKS" -> uuid)
      final client = Supabase.instance.client;
      final parentRes = await client.from('categories').select('id').ilike('name', mainCategoryName).maybeSingle();

      if (parentRes == null) {
        items = [];
        loading = false;
        notifyListeners();
        return;
      }

      final parentId = parentRes['id'] as String;

      // 2. Fetch its sub-categories
      final subs = await _repo.getSubCategories(parentId);
      subCategories = subs.map((e) => CategoryObj(e['id'], e['name'])).toList();

      // 3. Set default filter to include ALL sub-categories of this parent
      _currentCategoryIds = subCategories.map((e) => e.id).toList();
      _currentCategoryId = null; // "All" selected

      // 4. Fetch items
      await _fetchItems(reset: true);
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void filterBySubCategory(String? categoryId) {
    if (categoryId == null) {
      // Revert to "All" (all sub IDs)
      _currentCategoryId = null;
    } else {
      _currentCategoryId = categoryId;
    }
    _fetchItems(reset: true);
  }

  void setSearch(String query) {
    _searchQuery = query;
    _fetchItems(reset: true);
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    await _fetchItems(reset: false);
    loadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchItems({required bool reset}) async {
    if (reset) {
      _page = 1;
      items = [];
      hasMore = true;
      loading = true;
      notifyListeners();
    }

    try {
      // If specific sub-cat selected, use that. Else use list of all sub-cats.
      final singleId = _currentCategoryId;
      final listIds = _currentCategoryId == null ? _currentCategoryIds : null;

      final result = await _repo.getMenuItems(page: _page, pageSize: _pageSize, search: _searchQuery, categoryId: singleId, categoryIds: listIds);

      if (reset) {
        items = result;
      } else {
        items.addAll(result);
      }

      hasMore = result.length == _pageSize;
      if (!reset) _page++;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Simple fetch for Admin List
  Future<void> fetchAdminList() async {
    _currentCategoryIds = null;
    _currentCategoryId = null;
    _searchQuery = null;
    await _fetchItems(reset: true);
  }
}
