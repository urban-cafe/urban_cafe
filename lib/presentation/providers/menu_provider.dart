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
  String? _currentCategoryId;
  List<String>? _currentCategoryIds;

  String _searchQuery = '';

  int _page = 1;
  final int _pageSize = 20;
  bool hasMore = true;

  // Initializer for the Menu Screen
  Future<void> initForMainCategory(String mainCategoryName) async {
    // 1. CLEAR DATA IMMEDIATELY
    // This ensures the UI sees an empty list and shows the loading spinner
    // instead of the old data from the previous screen.
    items = [];
    subCategories = [];
    _currentCategoryId = null;
    _currentCategoryIds = null;
    error = null;

    // 2. Set loading to true and notify listeners to trigger the UI rebuild
    loading = true;
    notifyListeners();

    try {
      // 3. Find the ID of the Main Category
      final client = Supabase.instance.client;
      final parentRes = await client.from('categories').select('id').ilike('name', mainCategoryName).maybeSingle();

      if (parentRes == null) {
        loading = false;
        notifyListeners();
        return;
      }

      final parentId = parentRes['id'] as String;

      // 4. Fetch its sub-categories
      final subs = await _repo.getSubCategories(parentId);
      subCategories = subs.map((e) => CategoryObj(e['id'], e['name'])).toList();

      // 5. Set default filter to include ALL sub-categories of this parent
      _currentCategoryIds = subCategories.map((e) => e.id).toList();

      // 6. Fetch items (API Call)
      await _fetchItems(reset: true);
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  // NEW: Fetch all categories for Admin Filter
  Future<void> loadCategoriesForAdminFilter() async {
    try {
      final allCats = await _repo.getAllCategories();
      subCategories = allCats.map((e) => CategoryObj(e['id'], e['name'])).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading admin categories: $e");
    }
  }

  void filterBySubCategory(String? categoryId) {
    if (categoryId == null) {
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

  void resetSearch(String query) {
    _searchQuery = query;
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
      // Double check items are cleared if calling this directly
      if (items.isNotEmpty) items = [];
      hasMore = true;
      loading = true;
      notifyListeners();
    }

    try {
      final singleId = _currentCategoryId;
      final listIds = _currentCategoryId == null ? _currentCategoryIds : null;

      final result = await _repo.getMenuItems(page: _page, pageSize: _pageSize, search: _searchQuery, categoryId: singleId, categoryIds: listIds);

      if (reset) {
        items = result;
      } else {
        items.addAll(result);
      }

      hasMore = result.length == _pageSize;
      if (hasMore) _page++;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Simple fetch for Admin List
  Future<void> fetchAdminList() async {
    // Clear data here too
    items = [];
    _currentCategoryIds = null;
    _currentCategoryId = null;
    _searchQuery = '';
    error = null;

    loading = true;
    notifyListeners();

    await _fetchItems(reset: true);
  }
}
