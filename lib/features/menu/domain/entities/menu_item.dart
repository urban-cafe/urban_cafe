class MenuItemVariant {
  final String id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  const MenuItemVariant({required this.id, required this.name, required this.priceAdjustment, required this.isDefault});

  factory MenuItemVariant.fromJson(Map<String, dynamic> json) {
    return MenuItemVariant(id: json['id'] as String, name: json['name'] as String, priceAdjustment: (json['price_adjustment'] as num).toDouble(), isDefault: json['is_default'] as bool);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price_adjustment': priceAdjustment, 'is_default': isDefault};
}

class MenuItemAddon {
  final String id;
  final String name;
  final double price;

  const MenuItemAddon({required this.id, required this.name, required this.price});

  factory MenuItemAddon.fromJson(Map<String, dynamic> json) {
    return MenuItemAddon(id: json['id'] as String, name: json['name'] as String, price: (json['price'] as num).toDouble());
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

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

  // Customization
  final List<MenuItemVariant> variants;
  final List<MenuItemAddon> addons;

  const MenuItemEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    required this.imagePath,
    required this.imageUrl,
    required this.isAvailable,
    this.isMostPopular = false,
    this.isWeekendSpecial = false,
    required this.createdAt,
    required this.updatedAt,
    this.variants = const [],
    this.addons = const [],
  });
}
