import 'package:urban_cafe/domain/entities/menu_item.dart';

class CartItem {
  final MenuItemEntity menuItem;
  int quantity;
  String? notes;

  CartItem({required this.menuItem, this.quantity = 1, this.notes});

  double get totalPrice => menuItem.price * quantity;
}
