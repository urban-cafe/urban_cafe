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

  // 1. CACHE: Store Main Category IDs (Name -> ID) to save 1 DB call per switch
  final Map<String, String> _mainIdCache = {};

  List<MenuItemEntity> items = [];
  List<CategoryObj> subCategories = [];

  bool loading = false;
  bool loadingMore = false;
  String? error;

  String? _currentCategoryId;
  List<String>? _currentCategoryIds;
  String _searchQuery = '';

  int _page = 1;
  final int _pageSize = 10;
  bool hasMore = true;

  // Optimized Initializer
  Future<void> initForMainCategory(String mainCategoryName) async {
    // Only clear items if we are switching to a NEW main category
    // This prevents flashing if we just re-enter the same screen
    items = [];
    subCategories = [];
    _currentCategoryId = null;
    _currentCategoryIds = null;
    error = null;
    loading = true;

    // Notify immediately so Skeleton appears
    notifyListeners();

    try {
      // 2. CHECK CACHE FIRST
      String? parentId = _mainIdCache[mainCategoryName];

      if (parentId == null) {
        final client = Supabase.instance.client;
        final parentRes = await client.from('categories').select('id').ilike('name', mainCategoryName).maybeSingle();

        if (parentRes == null) {
          loading = false;
          notifyListeners();
          return;
        }
        parentId = parentRes['id'] as String;
        // Save to cache
        _mainIdCache[mainCategoryName] = parentId;
      }

      // 3. FETCH SUB-CATEGORIES
      final subs = await _repo.getSubCategories(parentId);
      subCategories = subs.map((e) => CategoryObj(e['id'], e['name'])).toList();

      // Set filter to allow ALL sub-categories by default
      _currentCategoryIds = subCategories.map((e) => e.id).toList();

      // 4. FETCH ITEMS (Now that we have the IDs)
      await _fetchItems(reset: true);
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  // ... (Keep existing fetchAdminList, setSearch, etc.)

  void filterBySubCategory(String? categoryId) {
    _currentCategoryId = categoryId;
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

  void resetSearch(String query) {
    _searchQuery = query;
    // Don't notify listeners here to avoid unnecessary rebuilds on dispose
  }

  void setSearch(String query) {
    _searchQuery = query;
    _fetchItems(reset: true);
  }

  Future<void> _fetchItems({required bool reset}) async {
    if (reset) {
      _page = 1;
      items = []; // Clear list for fresh load
      hasMore = true;
      loading = true;
      notifyListeners();
    }

    try {
      final singleId = _currentCategoryId;
      // If a specific sub is selected, use it. Otherwise use the list of ALL subs for this main category.
      final listIds = singleId == null ? _currentCategoryIds : null;

      // We block if listIds is NOT NULL and EMPTY (User Mode: Empty Category).
      // We ALLOW if listIds IS NULL (Admin Mode: Fetch Everything).
      if (singleId == null && (listIds != null && listIds.isEmpty)) {
        loading = false;
        notifyListeners();
        return;
      }

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

  // ... (keep fetchAdminList)
  Future<void> fetchAdminList() async {
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
