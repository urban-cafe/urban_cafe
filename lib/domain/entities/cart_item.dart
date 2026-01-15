import 'package:urban_cafe/domain/entities/menu_item.dart';

class CartItem {
  final MenuItemEntity menuItem;
  int quantity;
  String? notes;
  
  // Customization
  MenuItemVariant? selectedVariant;
  List<MenuItemAddon> selectedAddons;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.notes,
    this.selectedVariant,
    this.selectedAddons = const [],
  });

  double get unitPrice {
    double price = menuItem.price;
    if (selectedVariant != null) {
      price += selectedVariant!.priceAdjustment;
    }
    for (var addon in selectedAddons) {
      price += addon.price;
    }
    return price;
  }

  double get totalPrice => unitPrice * quantity;
}
