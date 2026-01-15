import 'package:flutter/foundation.dart';
import 'package:urban_cafe/domain/entities/cart_item.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';
import 'package:urban_cafe/domain/usecases/orders/create_order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  OrderType _orderType = OrderType.dineIn;
  
  // Dependency
  final CreateOrder? createOrderUseCase; // Optional for now to avoid breaking main.dart immediately

  CartProvider({this.createOrderUseCase});

  List<CartItem> get items => List.unmodifiable(_items);
  OrderType get orderType => _orderType;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool _isPlacingOrder = false;
  bool get isPlacingOrder => _isPlacingOrder;
  String? _error;
  String? get error => _error;

  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  Future<bool> placeOrder() async {
    if (createOrderUseCase == null) {
      _error = "Order feature not initialized";
      notifyListeners();
      return false;
    }
    
    if (_items.isEmpty) return false;

    _isPlacingOrder = true;
    _error = null;
    notifyListeners();

    final result = await createOrderUseCase!(CreateOrderParams(
      items: _items,
      totalAmount: totalAmount,
      type: _orderType,
    ));

    return result.fold(
      (failure) {
        _error = failure.message;
        _isPlacingOrder = false;
        notifyListeners();
        return false;
      },
      (orderId) {
        clearCart();
        _isPlacingOrder = false;
        notifyListeners();
        return true;
      },
    );
  }

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
