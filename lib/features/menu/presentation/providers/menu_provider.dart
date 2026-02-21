import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:urban_cafe/core/services/cache_service.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_category_by_name.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_sub_categories.dart';

class MenuProvider extends ChangeNotifier {
  final GetMainCategories getMainCategoriesUseCase;
  final GetSubCategories getSubCategoriesUseCase;
  final GetMenuItems getMenuItemsUseCase;
  final GetCategoryByName getCategoryByNameUseCase;

  // Cache service for reducing API calls
  final CacheService _cache;

  // 1. CACHE: Store Main Category IDs (Name -> ID) to save 1 DB call per switch
  final Map<String, String> _mainIdCache = {};

  // Store Main Categories List for UI
  List<Category> mainCategories = [];
  bool mainCategoriesLoading = false;

  List<MenuItemEntity> items = [];
  List<MenuItemEntity> popularItems = []; // New
  List<MenuItemEntity> specialItems = []; // New
  List<Category> subCategories = [];

  bool loading = false;
  bool loadingMore = false;
  String? error;

  String? _currentCategoryId;
  String? get currentCategoryId => _currentCategoryId; // Expose getter

  List<String>? _currentCategoryIds;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int _page = 1;
  final int _pageSize = 10;
  bool hasMore = true;
  bool _isInitializing = false; // Guard against duplicate concurrent init calls

  MenuProvider({required this.getMainCategoriesUseCase, required this.getSubCategoriesUseCase, required this.getMenuItemsUseCase, required this.getCategoryByNameUseCase, CacheService? cacheService})
    : _cache = cacheService ?? GetIt.I<CacheService>();

  Future<void> loadMainCategories() async {
    // Check in-memory first
    if (mainCategories.isNotEmpty) return;

    // Check TTL cache
    final cached = _cache.get<List<Category>>(CacheKeys.mainCategories);
    if (cached != null) {
      mainCategories = cached;
      for (var m in cached) {
        _mainIdCache[m.name] = m.id;
      }
      notifyListeners();
      return;
    }

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
        // Populate local cache
        for (var m in categories) {
          _mainIdCache[m.name] = m.id;
        }
        // Store in TTL cache (15 min - categories rarely change)
        _cache.set(CacheKeys.mainCategories, categories, ttl: CacheService.longTtl);
        mainCategoriesLoading = false;
        notifyListeners();
      },
    );
  }

  // New: Load Home Screen Data (Popular & Specials) with caching
  Future<void> loadHomeData({bool forceRefresh = false}) async {
    loading = true;
    notifyListeners();

    // Invalidate stale cache when forced (e.g. pull-to-refresh)
    if (forceRefresh) {
      _cache.remove(CacheKeys.popularItems);
      _cache.remove(CacheKeys.specialItems);
      _cache.remove(CacheKeys.mainCategories);
      popularItems = []; // Clear in-memory so isEmpty → skeleton shows
      specialItems = []; // Clear in-memory so isEmpty → skeleton shows
      mainCategories = []; // Reset so loadMainCategories() refetches
      _mainIdCache.clear();
    }

    // 1. Check Popular Items cache first
    final cachedPopular = _cache.get<List<MenuItemEntity>>(CacheKeys.popularItems);
    if (cachedPopular != null) {
      popularItems = cachedPopular;
    } else {
      final popResult = await getMenuItemsUseCase(const GetMenuItemsParams(page: 1, pageSize: 8, isMostPopular: true));
      popResult.fold((f) => debugPrint('Error loading popular: ${f.message}'), (list) {
        popularItems = list;
        _cache.set(CacheKeys.popularItems, list, ttl: CacheService.mediumTtl);
      });
    }

    // 2. Check Weekend Specials cache first
    final cachedSpecials = _cache.get<List<MenuItemEntity>>(CacheKeys.specialItems);
    if (cachedSpecials != null) {
      specialItems = cachedSpecials;
    } else {
      final specResult = await getMenuItemsUseCase(const GetMenuItemsParams(page: 1, pageSize: 5, isWeekendSpecial: true));
      specResult.fold((f) => debugPrint('Error loading specials: ${f.message}'), (list) {
        specialItems = list;
        _cache.set(CacheKeys.specialItems, list, ttl: CacheService.mediumTtl);
      });
    }

    // 3. Main Categories (if not loaded)
    await loadMainCategories();

    loading = false;
    notifyListeners();
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

  // ── MENU SCREEN LIFECYCLE ─────────────────────────────────────────────────

  /// Called by MenuScreen.dispose() so that re-entering the screen always
  /// shows fresh data instead of leftover state from the previous visit.
  void resetMenuState() {
    items = [];
    subCategories = [];
    _currentCategoryId = null;
    _currentCategoryIds = null;
    _searchQuery = '';
    hasMore = true;
    _page = 1;
    error = null;
    loading = false;
    loadingMore = false;
    _isInitializing = false;
    // Intentionally NOT calling notifyListeners() — screen is being disposed.
  }

  // Optimized Initializer
  Future<void> initForMainCategory(String mainCategoryName) async {
    if (_isInitializing) return; // Prevent duplicate concurrent calls
    _isInitializing = true;
    // Only clear items if we are switching to a NEW main category
    // This prevents flashing if we just re-enter the same screen
    items = [];
    subCategories = [];
    _currentCategoryId = null;
    _currentCategoryIds = null;
    _searchQuery = ''; // Reset search query
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
          },
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
        },
      );
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  // Initializer for Filtered Views (Popular / Special)
  Future<void> initForFilter(String filterType) async {
    if (_isInitializing) return;
    _isInitializing = true;
    items = [];
    subCategories = [];
    _currentCategoryId = null;
    _currentCategoryIds = null;
    _searchQuery = '';
    error = null;
    loading = true;
    notifyListeners();

    try {
      final isPopular = filterType == 'popular';
      final isSpecial = filterType == 'special';

      final result = await getMenuItemsUseCase(
        GetMenuItemsParams(
          page: 1,
          pageSize: 20, // Load more for filtered views
          isMostPopular: isPopular,
          isWeekendSpecial: isSpecial,
        ),
      );

      result.fold(
        (failure) {
          error = failure.message;
        },
        (newItems) {
          items = newItems;
          hasMore = newItems.length == 20;
          if (hasMore) _page++;
        },
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _isInitializing = false;
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

      final result = await getMenuItemsUseCase(GetMenuItemsParams(page: _page, pageSize: _pageSize, search: _searchQuery, categoryId: singleId, categoryIds: listIds));

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
        },
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
