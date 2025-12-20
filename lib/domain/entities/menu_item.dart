class MenuItemEntity {
  final String id;
  final String name;
  final String? description;
  final double price;

  // New relational fields
  final String? categoryId;
  final String? categoryName;

  final String? imagePath;
  final String? imageUrl;
  final bool isAvailable;
  final bool isMostPopular;
  final bool isWeekendSpecial;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemEntity({required this.id, required this.name, required this.description, required this.price, this.categoryId, this.categoryName, required this.imagePath, required this.imageUrl, required this.isAvailable, this.isMostPopular = false, this.isWeekendSpecial = false, required this.createdAt, required this.updatedAt});
}
