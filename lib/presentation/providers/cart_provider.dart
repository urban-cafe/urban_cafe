import 'package:flutter/foundation.dart';
import 'package:urban_cafe/domain/entities/cart_item.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(MenuItemEntity menuItem, {int quantity = 1, String? notes}) {
    // Check if item already exists with same notes
    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id && item.notes == notes,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        menuItem: menuItem,
        quantity: quantity,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(item);
      return;
    }
    item.quantity = newQuantity;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
