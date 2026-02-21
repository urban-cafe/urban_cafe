import 'package:flutter/foundation.dart' hide Category;
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/app_exception.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/services/menu_cache_database.dart';
import 'package:urban_cafe/features/menu/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/features/menu/domain/entities/category.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  static const String table = 'menu_items';
  static const String catTable = 'categories';

  final SupabaseClient _client;
  final MenuCacheDatabase _cache;

  MenuRepositoryImpl(this._client, this._cache);

  // ── Read Methods (Cache-First) ────────────────────────────────

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? categoryId,
    List<String>? categoryIds,
    bool? isMostPopular,
    bool? isWeekendSpecial,
  }) async {
    if (!Env.isConfigured) return const Left(ServerFailure('App not configured.', code: 'env_not_configured'));

    // 1. Try cache first (only for page 1 / non-search queries)
    if (_cache.isAvailable && page == 1 && (search == null || search.trim().isEmpty)) {
      final cached = _cache.getMenuItems(categoryId: categoryId, categoryIds: categoryIds, isMostPopular: isMostPopular, isWeekendSpecial: isWeekendSpecial, page: page, pageSize: pageSize);
      if (cached.isNotEmpty) {
        // Return cached immediately, refresh in background
        _refreshMenuItemsInBackground(categoryId: categoryId, categoryIds: categoryIds, isMostPopular: isMostPopular, isWeekendSpecial: isWeekendSpecial);
        return Right(cached);
      }
    }

    // 2. Fetch from Supabase
    try {
      final items = await _fetchMenuItemsFromSupabase(
        page: page,
        pageSize: pageSize,
        search: search,
        categoryId: categoryId,
        categoryIds: categoryIds,
        isMostPopular: isMostPopular,
        isWeekendSpecial: isWeekendSpecial,
      );

      // Cache the results
      if (_cache.isAvailable && items.isNotEmpty) {
        _cache.upsertMenuItems(items);
      }

      return Right(items);
    } catch (e) {
      // 3. If network fails, return whatever cache has
      if (_cache.isAvailable) {
        final cached = _cache.getMenuItems(
          categoryId: categoryId,
          categoryIds: categoryIds,
          search: search,
          isMostPopular: isMostPopular,
          isWeekendSpecial: isWeekendSpecial,
          page: page,
          pageSize: pageSize,
        );
        if (cached.isNotEmpty) return Right(cached);
      }
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getMainCategories() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    // 1. Try cache
    if (_cache.isAvailable) {
      final cached = _cache.getCategories();
      if (cached.isNotEmpty) {
        _refreshCategoriesInBackground();
        return Right(cached);
      }
    }

    // 2. Fetch from Supabase
    try {
      final data = await _client.from(catTable).select('id, name').isFilter('parent_id', null).order('name', ascending: true);

      final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();

      // Cache
      if (_cache.isAvailable) {
        _cache.upsertCategories(categories);
      }

      return Right(categories);
    } catch (e) {
      // Offline fallback
      if (_cache.isAvailable) {
        final cached = _cache.getCategories();
        if (cached.isNotEmpty) return Right(cached);
      }
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSubCategories(String parentId) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    // 1. Try cache
    if (_cache.isAvailable) {
      final cached = _cache.getCategories(parentId: parentId);
      if (cached.isNotEmpty) {
        _refreshSubCategoriesInBackground(parentId);
        return Right(cached);
      }
    }

    // 2. Fetch from Supabase
    try {
      final data = await _client.from(catTable).select('id, name').eq('parent_id', parentId).order('name', ascending: true);

      final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();

      if (_cache.isAvailable) {
        _cache.upsertCategories(categories, parentId: parentId);
      }

      return Right(categories);
    } catch (e) {
      if (_cache.isAvailable) {
        final cached = _cache.getCategories(parentId: parentId);
        if (cached.isNotEmpty) return Right(cached);
      }
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Category?>> getCategoryByName(String name) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final res = await _client.from(catTable).select('id, name').ilike('name', name).maybeSingle();

      if (res == null) return const Right(null);
      return Right(Category(id: res['id'] as String, name: res['name'] as String));
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final data = await _client.from(catTable).select('id, name').order('name', ascending: true);

      final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();
      return Right(categories);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  // ── Write Methods (Supabase-first, cache on success) ──────────

  @override
  Future<Either<Failure, String>> createCategory(String name, {String? parentId}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final res = await _client.from(catTable).insert({'name': name, 'parent_id': parentId}).select('id').single();
      final id = res['id'] as String;

      // Update cache
      if (_cache.isAvailable) {
        _cache.upsertCategories([Category(id: id, name: name)], parentId: parentId);
      }

      return Right(id);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(catTable).delete().eq('id', id);
      return const Right(null);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(String id, String newName) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(catTable).update({'name': newName}).eq('id', id);
      return const Right(null);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> createMenuItem({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    bool isAvailable = true,
    bool isMostPopular = false,
    bool isWeekendSpecial = false,
    String? imagePath,
    String? imageUrl,
  }) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      final inserted = await _client
          .from(table)
          .insert({
            'name': name,
            'description': description,
            'price': price,
            'category_id': categoryId,
            'image_path': imagePath,
            'image_url': imageUrl,
            'is_available': isAvailable,
            'is_most_popular': isMostPopular,
            'is_weekend_special': isWeekendSpecial,
          })
          .select('*, categories(name), menu_item_variants(*), menu_item_addons(*)')
          .single();

      final item = MenuItemDto.fromMap(inserted).toEntity();

      // Update cache
      if (_cache.isAvailable) {
        _cache.upsertMenuItems([item]);
      }

      return Right(item);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> updateMenuItem({
    required String id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    bool? isAvailable,
    bool? isMostPopular,
    bool? isWeekendSpecial,
    String? imagePath,
    String? imageUrl,
  }) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      final updated = await _client
          .from(table)
          .update({
            'name': ?name,
            'description': ?description,
            'price': ?price,
            'category_id': ?categoryId,
            'is_available': ?isAvailable,
            'is_most_popular': ?isMostPopular,
            'is_weekend_special': ?isWeekendSpecial,
            'image_path': ?imagePath,
            'image_url': ?imageUrl,
          })
          .eq('id', id)
          .select('*, categories(name), menu_item_variants(*), menu_item_addons(*)')
          .single();

      final item = MenuItemDto.fromMap(updated).toEntity();

      // Update cache
      if (_cache.isAvailable) {
        _cache.upsertMenuItems([item]);
      }

      return Right(item);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(String id) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(table).delete().eq('id', id);

      // Remove from cache
      if (_cache.isAvailable) {
        _cache.deleteMenuItem(id);
      }

      return const Right(null);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  // ── Background Sync Helpers ───────────────────────────────────

  Future<List<MenuItemEntity>> _fetchMenuItemsFromSupabase({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? categoryId,
    List<String>? categoryIds,
    bool? isMostPopular,
    bool? isWeekendSpecial,
  }) async {
    var query = _client.from(table).select('*, categories(name), menu_item_variants(*), menu_item_addons(*)');

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query = query.inFilter('category_id', categoryIds);
    } else if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (isMostPopular == true) {
      query = query.eq('is_most_popular', true);
    }
    if (isWeekendSpecial == true) {
      query = query.eq('is_weekend_special', true);
    }

    final data = await query.order('name', ascending: true).range((page - 1) * pageSize, page * pageSize - 1);

    return (data as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();
  }

  void _refreshMenuItemsInBackground({String? categoryId, List<String>? categoryIds, bool? isMostPopular, bool? isWeekendSpecial}) {
    // Fire-and-forget background refresh
    _fetchMenuItemsFromSupabase(
          page: 1,
          pageSize: 50, // Fetch more to populate cache broadly
          categoryId: categoryId,
          categoryIds: categoryIds,
          isMostPopular: isMostPopular,
          isWeekendSpecial: isWeekendSpecial,
        )
        .then((items) {
          if (items.isNotEmpty) {
            _cache.upsertMenuItems(items);
            _cache.setLastSyncTime(DateTime.now());
          }
        })
        .catchError((e) {
          debugPrint('[MenuCache] Background refresh failed: $e');
        });
  }

  void _refreshCategoriesInBackground() {
    _client
        .from(catTable)
        .select('id, name')
        .isFilter('parent_id', null)
        .order('name', ascending: true)
        .then((data) {
          final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();
          if (categories.isNotEmpty) {
            _cache.upsertCategories(categories);
          }
        })
        .catchError((e) {
          debugPrint('[MenuCache] Background category refresh failed: $e');
        });
  }

  void _refreshSubCategoriesInBackground(String parentId) {
    _client
        .from(catTable)
        .select('id, name')
        .eq('parent_id', parentId)
        .order('name', ascending: true)
        .then((data) {
          final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();
          if (categories.isNotEmpty) {
            _cache.upsertCategories(categories, parentId: parentId);
          }
        })
        .catchError((e) {
          debugPrint('[MenuCache] Background subcategory refresh failed: $e');
        });
  }
}
