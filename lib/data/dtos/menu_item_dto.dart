import 'package:urban_cafe/domain/entities/menu_item.dart';

class MenuItemDto {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? categoryId;
  final String? categoryName;
  final String? imagePath;
  final String? imageUrl;
  final bool isAvailable;
  final bool isMostPopular;
  final bool isWeekendSpecial;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemDto({required this.id, required this.name, required this.description, required this.price, this.categoryId, this.categoryName, required this.imagePath, required this.imageUrl, required this.isAvailable, required this.isMostPopular, required this.isWeekendSpecial, required this.createdAt, required this.updatedAt});

  factory MenuItemDto.fromMap(Map<String, dynamic> map) {
    // Supabase join result: { ..., "categories": { "name": "Tea" } }
    final catData = map['categories'] as Map<String, dynamic>?;

    return MenuItemDto(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.parse(map['price'].toString()),

      // Map Foreign Keys
      categoryId: map['category_id'] as String?,
      categoryName: catData?['name'] as String?,

      imagePath: map['image_path'] as String?,
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as bool?) ?? true,
      isMostPopular: (map['is_most_popular'] as bool?) ?? false,
      isWeekendSpecial: (map['is_weekend_special'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MenuItemEntity toEntity() => MenuItemEntity(id: id, name: name, description: description, price: price, categoryId: categoryId, categoryName: categoryName, imagePath: imagePath, imageUrl: imageUrl, isAvailable: isAvailable, isMostPopular: isMostPopular, isWeekendSpecial: isWeekendSpecial, createdAt: createdAt, updatedAt: updatedAt);
}
