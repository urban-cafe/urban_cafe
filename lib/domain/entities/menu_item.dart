class MenuItemEntity {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imagePath;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });
}
