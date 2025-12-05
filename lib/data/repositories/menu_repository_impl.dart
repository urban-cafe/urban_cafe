import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  static const String table = 'menu_items';
  static const String categoriesTable = 'categories';

  SupabaseClient get _client => SupabaseClientProvider.client;

  @override
  Future<List<MenuItemEntity>> getMenuItems({int page = 1, int pageSize = 20, String? search, String? category, List<String>? categories}) async {
    if (!Env.isConfigured) {
      return _offlineSeed();
    }
    try {
      final from = _client.from(table);
      var filter = from.select();
      if (search != null && search.trim().isNotEmpty) {
        filter = filter.ilike('name', '%$search%');
      }
      if (categories != null && categories.isNotEmpty) {
        filter = filter.inFilter('category', categories);
      } else if (category != null && category.trim().isNotEmpty) {
        filter = filter.eq('category', category);
      }
      final data = await filter.order('created_at', ascending: false).range((page - 1) * pageSize, page * pageSize - 1);
      return (data as List<dynamic>).map((e) => MenuItemDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();
    } catch (_) {
      return _offlineSeed();
    }
  }

  @override
  Future<List<String>> getCategories() async {
    if (!Env.isConfigured) {
      return ['Coffee', 'Tea', 'Food'];
    }
    final data = await _client.from(table).select('category').not('category', 'is', null).order('category', ascending: true);
    final list = (data as List<dynamic>).map((e) => (e as Map<String, dynamic>)['category'] as String).toList();
    return list.toSet().toList();
  }

  @override
  Future<List<String>> getMainCategories() async {
    if (!Env.isConfigured) {
      return ['COLD DRINKS', 'HOT DRINKS', 'FOOD'];
    }
    try {
      final data = await _client.from(categoriesTable).select('name,parent_id').isFilter('parent_id', null).order('name');
      return (data as List<dynamic>).map((e) => (e as Map<String, dynamic>)['name'] as String).toList();
    } catch (_) {
      return ['COLD DRINKS', 'HOT DRINKS', 'FOOD'];
    }
  }

  @override
  Future<List<String>> getSubCategories(String parentName) async {
    if (!Env.isConfigured) {
      if (parentName.toUpperCase() == 'COLD DRINKS') {
        return ['Tea', 'Soda', 'Matcha', 'Milkshake Cheesy', 'Tiramisu Special Drinks', 'Frappe', 'Refresh Fusion', 'Coffee', 'Seasonal Fruits'];
      }
      if (parentName.toUpperCase() == 'HOT DRINKS') {
        return ['Coffee'];
      }
      return [];
    }
    try {
      final parent = await _client.from(categoriesTable).select('id').eq('name', parentName).limit(1);
      final parentList = parent as List<dynamic>;
      final parentId = parentList.isNotEmpty ? (parentList.first as Map<String, dynamic>)['id'] : null;
      if (parentId == null) return [];
      final data = await _client.from(categoriesTable).select('name,parent_id').eq('parent_id', parentId).order('name');
      return (data as List<dynamic>).map((e) => (e as Map<String, dynamic>)['name'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MenuItemEntity> createMenuItem({required String name, String? description, required double price, String? category, bool isAvailable = true, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) {
      throw Exception('Supabase not configured');
    }
    final inserted = await _client.from(table).insert({'name': name, 'description': description, 'price': price, 'category': category, 'image_path': imagePath, 'image_url': imageUrl, 'is_available': isAvailable}).select().single();
    return MenuItemDto.fromMap(inserted).toEntity();
  }

  @override
  Future<MenuItemEntity> updateMenuItem({required String id, String? name, String? description, double? price, String? category, bool? isAvailable, String? imagePath, String? imageUrl}) async {
    if (!Env.isConfigured) {
      throw Exception('Supabase not configured');
    }
    final updated = await _client.from(table).update({if (name != null) 'name': name, if (description != null) 'description': description, if (price != null) 'price': price, if (category != null) 'category': category, if (isAvailable != null) 'is_available': isAvailable, if (imagePath != null) 'image_path': imagePath, if (imageUrl != null) 'image_url': imageUrl}).eq('id', id).select().single();
    return MenuItemDto.fromMap(updated).toEntity();
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    if (!Env.isConfigured) {
      throw Exception('Supabase not configured');
    }
    await _client.from(table).delete().eq('id', id);
  }

  List<MenuItemEntity> _offlineSeed() {
    final now = DateTime.now();
    return [MenuItemEntity(id: 'seed-1', name: 'Espresso', description: 'Rich and bold espresso shot', price: 2.99, category: 'Coffee', imagePath: null, imageUrl: 'https://picsum.photos/seed/espresso/800/600', isAvailable: true, createdAt: now, updatedAt: now), MenuItemEntity(id: 'seed-2', name: 'Cappuccino', description: 'Espresso with steamed milk and foam', price: 3.99, category: 'Coffee', imagePath: null, imageUrl: 'https://picsum.photos/seed/cappuccino/800/600', isAvailable: true, createdAt: now, updatedAt: now), MenuItemEntity(id: 'seed-3', name: 'Avocado Toast', description: 'Sourdough with smashed avocado', price: 6.49, category: 'Food', imagePath: null, imageUrl: 'https://picsum.photos/seed/avocado/800/600', isAvailable: true, createdAt: now, updatedAt: now)];
  }
}
