import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  static const String table = 'menu_items';
  static const String catTable = 'categories';

  SupabaseClient get _client => SupabaseClientProvider.client;

  @override
  Future<List<MenuItemEntity>> getMenuItems({int page = 1, int pageSize = 20, String? search, String? categoryId, List<String>? categoryIds}) async {
    if (!Env.isConfigured) return [];

    try {
      // JOIN categories to get the name for display
      var query = _client.from(table).select('*, categories(name)');

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      // Filter by IDs
      if (categoryIds != null && categoryIds.isNotEmpty) {
        query = query.inFilter('category_id', categoryIds);
      } else if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final data = await query.order('created_at', ascending: false).range((page - 1) * pageSize, page * pageSize - 1);

      return (data as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      // Return empty or throw based on preference
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMainCategories() async {
    if (!Env.isConfigured) return [];
    final data = await _client.from(catTable).select('id, name').isFilter('parent_id', null).order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getSubCategories(String parentId) async {
    if (!Env.isConfigured) return [];
    final data = await _client.from(catTable).select('id, name').eq('parent_id', parentId).order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    if (!Env.isConfigured) return [];
    // Fetch all categories (Main and Sub) to show in the filter list
    final data = await _client.from(catTable).select('id, name').order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<String> createCategory(String name, {String? parentId}) async {
    if (!Env.isConfigured) throw Exception('Supabase not configured');
    final res = await _client.from(catTable).insert({'name': name, 'parent_id': parentId}).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> updateCategory(String id, String newName) async {
    if (!Env.isConfigured) throw Exception('Supabase not configured');
    await _client.from(catTable).update({'name': newName}).eq('id', id);
  }

  @override
  Future<MenuItemEntity> createMenuItem({required String name, String? description, required double price, String? categoryId, bool isAvailable = true, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) throw Exception('No Config');

    final inserted = await _client.from(table).insert({'name': name, 'description': description, 'price': price, 'category_id': categoryId, 'image_path': imagePath, 'image_url': imageUrl, 'is_available': isAvailable}).select('*, categories(name)').single();

    return MenuItemDto.fromMap(inserted).toEntity();
  }

  @override
  Future<MenuItemEntity> updateMenuItem({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) throw Exception('No Config');

    final updated = await _client.from(table).update({if (name != null) 'name': name, if (description != null) 'description': description, if (price != null) 'price': price, if (categoryId != null) 'category_id': categoryId, if (isAvailable != null) 'is_available': isAvailable, if (imagePath != null) 'image_path': imagePath, if (imageUrl != null) 'image_url': imageUrl}).eq('id', id).select('*, categories(name)').single();

    return MenuItemDto.fromMap(updated).toEntity();
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    if (!Env.isConfigured) return;
    await _client.from(table).delete().eq('id', id);
  }
}
