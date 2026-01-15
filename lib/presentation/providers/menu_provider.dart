import 'package:flutter/material.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/category.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/usecases/get_category_by_name.dart';
import 'package:urban_cafe/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/domain/usecases/get_sub_categories.dart';

class MenuProvider extends ChangeNotifier {
  final GetMainCategories getMainCategoriesUseCase;
  final GetSubCategories getSubCategoriesUseCase;
  final GetMenuItems getMenuItemsUseCase;
  final GetCategoryByName getCategoryByNameUseCase;

  // 1. CACHE: Store Main Category IDs (Name -> ID) to save 1 DB call per switch
  final Map<String, String> _mainIdCache = {};
  
  // Store Main Categories List for UI
  List<Category> mainCategories = [];
  bool mainCategoriesLoading = false;

  List<MenuItemEntity> items = [];
  List<Category> subCategories = [];

  bool loading = false;
  bool loadingMore = false;
  String? error;

  String? _currentCategoryId;
  String? get currentCategoryId => _currentCategoryId; // Expose getter

  List<String>? _currentCategoryIds;
  String _searchQuery = '';

  int _page = 1;
  final int _pageSize = 10;
  bool hasMore = true;

  MenuProvider({
    required this.getMainCategoriesUseCase,
    required this.getSubCategoriesUseCase,
    required this.getMenuItemsUseCase,
    required this.getCategoryByNameUseCase,
  });

  // New method to fetch main categories
  Future<void> loadMainCategories() async {
    if (mainCategories.isNotEmpty) return; // Return cached if available
    
    mainCategoriesLoading = true;
    notifyListeners();

    final result = await getMainCategoriesUseCase(NoParams());
    result.fold(
      (failure) {
        error = failure.message;
        mainCategoriesLoading = false;
        notifyListeners();
      },
      (categories) {
        mainCategories = categories;
        // Populate cache
        for (var m in categories) {
          _mainIdCache[m.name] = m.id;
        }
        mainCategoriesLoading = false;
        notifyListeners();
      },
    );
  }

  // Deprecated: Use loadMainCategories() and access mainCategories property instead
  Future<List<Category>> getMainCategories() async {
    await loadMainCategories();
    return mainCategories;
  }

  IconData getIconForCategory(String name) {
    return switch (name.toUpperCase()) {
      'COFFEE' => Icons.local_cafe_rounded,
      'DRINKS' => Icons.local_drink_rounded,
      'FOOD' => Icons.restaurant_menu_rounded,
      'BREAD & CAKES' => Icons.bakery_dining_rounded,
      _ => Icons.category_outlined, // Default fallback
    };
  }

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
        final result = await getCategoryByNameUseCase(GetCategoryByNameParams(mainCategoryName));
        
        await result.fold(
          (failure) async {
            error = failure.message;
            loading = false;
            notifyListeners();
          },
          (category) async {
            if (category == null) {
              loading = false;
              notifyListeners();
              return;
            }
            parentId = category.id;
            // Save to cache
            _mainIdCache[mainCategoryName] = parentId!;
          }
        );
      }
      
      if (parentId == null) return;

      // 3. FETCH SUB-CATEGORIES
      final subsResult = await getSubCategoriesUseCase(GetSubCategoriesParams(parentId!));
      
      await subsResult.fold(
        (failure) async {
          error = failure.message;
          loading = false;
          notifyListeners();
        },
        (subs) async {
          subCategories = subs;
          // Set filter to allow ALL sub-categories by default
          _currentCategoryIds = subCategories.map((e) => e.id).toList();

          // 4. FETCH ITEMS (Now that we have the IDs)
          await _fetchItems(reset: true);
        }
      );

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

      final result = await getMenuItemsUseCase(GetMenuItemsParams(
        page: _page, 
        pageSize: _pageSize, 
        search: _searchQuery, 
        categoryId: singleId, 
        categoryIds: listIds
      ));

      result.fold(
        (failure) {
          error = failure.message;
        },
        (newItems) {
          if (reset) {
            items = newItems;
          } else {
            items.addAll(newItems);
          }

          hasMore = newItems.length == _pageSize;
          if (hasMore) _page++;
        }
      );

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
