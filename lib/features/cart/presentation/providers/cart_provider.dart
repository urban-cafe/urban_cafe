import 'package:flutter/foundation.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';
import 'package:urban_cafe/features/orders/domain/usecases/create_order.dart';

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

  // Loyalty Logic
  bool _usePoints = false;
  int _availablePoints = 0;

  bool get usePoints => _usePoints;
  static const int pointsPerUnit = 10; // 10 points = 1 currency unit

  double get discountAmount {
    if (!_usePoints) return 0.0;
    // Max discount is total amount (free order)
    final maxPointsNeeded = (totalAmount * pointsPerUnit).ceil();
    final pointsToUse = _availablePoints < maxPointsNeeded ? _availablePoints : maxPointsNeeded;
    return pointsToUse / pointsPerUnit;
  }

  int get pointsToRedeem {
    if (!_usePoints) return 0;
    return (discountAmount * pointsPerUnit).toInt();
  }

  double get finalTotal => totalAmount - discountAmount;

  void toggleUsePoints(bool value, int userPoints) {
    _usePoints = value;
    _availablePoints = userPoints;
    notifyListeners();
  }

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

    try {
      final result = await createOrderUseCase!(
        CreateOrderParams(
          items: _items,
          totalAmount: finalTotal, // Use final total (discounted)
          type: _orderType,
          pointsRedeemed: pointsToRedeem,
        ),
      );

      return result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
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
    } catch (e) {
      _error = 'Failed to place order. Please try again.';
      _isPlacingOrder = false;
      notifyListeners();
      return false;
    }
  }

  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Connection failed. Please check your internet and try again.';
    }

    if (lowerError.contains('insufficient') || lowerError.contains('not enough points')) {
      return 'You don\'t have enough loyalty points for this discount.';
    }

    // Return original message if no mapping found
    return technicalError;
  }

  void addToCart(MenuItemEntity menuItem, {int quantity = 1, String? notes, MenuItemVariant? selectedVariant, List<MenuItemAddon> selectedAddons = const []}) {
    // Check if item already exists with same configuration (variant, addons, notes)
    final existingIndex = _items.indexWhere((item) {
      if (item.menuItem.id != menuItem.id) return false;
      if (item.notes != notes) return false;

      // Check Variant
      if (item.selectedVariant?.id != selectedVariant?.id) return false;

      // Check Addons (Sort and compare IDs)
      final existingAddonIds = item.selectedAddons.map((e) => e.id).toSet();
      final newAddonIds = selectedAddons.map((e) => e.id).toSet();

      return setEquals(existingAddonIds, newAddonIds);
    });

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(menuItem: menuItem, quantity: quantity, notes: notes, selectedVariant: selectedVariant, selectedAddons: selectedAddons));
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
    _usePoints = false;
    _availablePoints = 0;
    notifyListeners();
  }
}
