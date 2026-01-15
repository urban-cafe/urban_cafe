import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/domain/entities/category.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  static const String table = 'menu_items';
  static const String catTable = 'categories';

  SupabaseClient get _client => SupabaseClientProvider.client;

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems({int page = 1, int pageSize = 10, String? search, String? categoryId, List<String>? categoryIds}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      // JOIN categories, variants, and addons
      var query = _client.from(table).select('*, categories(name), menu_item_variants(*), menu_item_addons(*)');

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      // Filter by IDs
      if (categoryIds != null && categoryIds.isNotEmpty) {
        query = query.inFilter('category_id', categoryIds);
      } else if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final data = await query.order('name', ascending: true).range((page - 1) * pageSize, page * pageSize - 1);

      final items = (data as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();

      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getMainCategories() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final data = await _client.from(catTable).select('id, name').isFilter('parent_id', null).order('name', ascending: true);

      final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSubCategories(String parentId) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final data = await _client.from(catTable).select('id, name').eq('parent_id', parentId).order('name', ascending: true);

      final categories = (data as List<dynamic>).map((e) => Category(id: e['id'] as String, name: e['name'] as String)).toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createCategory(String name, {String? parentId}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final res = await _client.from(catTable).insert({'name': name, 'parent_id': parentId}).select('id').single();
      return Right(res['id'] as String);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(catTable).delete().eq('id', id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(String id, String newName) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(catTable).update({'name': newName}).eq('id', id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> createMenuItem({required String name, String? description, required double price, String? categoryId, bool isAvailable = true, bool isMostPopular = false, bool isWeekendSpecial = false, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      final inserted = await _client.from(table).insert({'name': name, 'description': description, 'price': price, 'category_id': categoryId, 'image_path': imagePath, 'image_url': imageUrl, 'is_available': isAvailable, 'is_most_popular': isMostPopular, 'is_weekend_special': isWeekendSpecial}).select('*, categories(name)').single();

      return Right(MenuItemDto.fromMap(inserted).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> updateMenuItem({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, bool? isMostPopular, bool? isWeekendSpecial, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      final updated = await _client.from(table).update({if (name != null) 'name': name, if (description != null) 'description': description, if (price != null) 'price': price, if (categoryId != null) 'category_id': categoryId, if (isAvailable != null) 'is_available': isAvailable, if (isMostPopular != null) 'is_most_popular': isMostPopular, if (isWeekendSpecial != null) 'is_weekend_special': isWeekendSpecial, if (imagePath != null) 'image_path': imagePath, if (imageUrl != null) 'image_url': imageUrl}).eq('id', id).select('*, categories(name)').single();

      return Right(MenuItemDto.fromMap(updated).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(String id) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      await _client.from(table).delete().eq('id', id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFavorites() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Left(AuthFailure('User not logged in'));

      final data = await _client.from('favorites').select('menu_item_id').eq('user_id', user.id);
      final ids = (data as List<dynamic>).map((e) => e['menu_item_id'] as String).toList();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getFavoriteItems() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Left(AuthFailure('User not logged in'));

      // 1. Get IDs
      final favRes = await _client.from('favorites').select('menu_item_id').eq('user_id', user.id);
      final ids = (favRes as List<dynamic>).map((e) => e['menu_item_id'] as String).toList();

      if (ids.isEmpty) return const Right([]);

      // 2. Fetch Items with customizations
      final itemsRes = await _client.from(table).select('*, categories(name), menu_item_variants(*), menu_item_addons(*)').inFilter('id', ids).order('name', ascending: true);

      final items = (itemsRes as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String menuItemId) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Left(AuthFailure('User not logged in'));

      // Check if exists
      final exists = await _client.from('favorites').select().eq('user_id', user.id).eq('menu_item_id', menuItemId).maybeSingle();

      if (exists != null) {
        // Remove
        await _client.from('favorites').delete().eq('id', exists['id']);
      } else {
        // Add
        await _client.from('favorites').insert({'user_id': user.id, 'menu_item_id': menuItemId});
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
