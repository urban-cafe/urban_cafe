import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';
import 'package:urban_cafe/features/pos/domain/usecases/create_pos_order.dart';
import 'package:urban_cafe/features/pos/domain/usecases/get_pos_orders.dart';
import 'package:urban_cafe/features/pos/domain/usecases/sync_pos_orders.dart';

class PosProvider extends ChangeNotifier {
  final CreatePosOrder createPosOrderUseCase;
  final GetPosOrders getPosOrdersUseCase;
  final SyncPosOrders syncPosOrdersUseCase;
  final PosRepository repository;
  final Connectivity connectivity;

  PosProvider({required this.createPosOrderUseCase, required this.getPosOrdersUseCase, required this.syncPosOrdersUseCase, required this.repository, required this.connectivity});

  // ─────────────────────────────────────────────────────────
  // Cart State
  // ─────────────────────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal; // Can add tax logic here later

  // ─────────────────────────────────────────────────────────
  // Order State
  // ─────────────────────────────────────────────────────────
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  String? _error;
  String? get error => _error;
  PosOrder? _lastCompletedOrder;
  PosOrder? get lastCompletedOrder => _lastCompletedOrder;

  // ─────────────────────────────────────────────────────────
  // Order History
  // ─────────────────────────────────────────────────────────
  List<PosOrder> _todayOrders = [];
  List<PosOrder> get todayOrders => _todayOrders;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;
  double get todayTotal => _todayOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

  // ─────────────────────────────────────────────────────────
  // Sync State
  // ─────────────────────────────────────────────────────────
  int _pendingOrderCount = 0;
  int get pendingOrderCount => _pendingOrderCount;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription? _connectivitySub;

  /// Initialize connectivity monitoring and auto-sync.
  void init() {
    _checkConnectivity();
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
        if (online) _attemptSync();
      }
    });
    _loadPendingCount();
  }

  Future<void> _checkConnectivity() async {
    final result = await connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> _loadPendingCount() async {
    _pendingOrderCount = await repository.getPendingOrderCount();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // Cart Operations
  // ─────────────────────────────────────────────────────────
  void addToCart(MenuItemEntity menuItem, {int quantity = 1, MenuItemVariant? selectedVariant, List<MenuItemAddon> selectedAddons = const []}) {
    final existingIndex = _cartItems.indexWhere((item) {
      if (item.menuItem.id != menuItem.id) return false;
      if (item.selectedVariant?.id != selectedVariant?.id) return false;
      final existingIds = item.selectedAddons.map((e) => e.id).toSet();
      final newIds = selectedAddons.map((e) => e.id).toSet();
      return setEquals(existingIds, newIds);
    });

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(menuItem: menuItem, quantity: quantity, selectedVariant: selectedVariant, selectedAddons: selectedAddons));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // Order Submission
  // ─────────────────────────────────────────────────────────
  Future<bool> completeOrder({required PosPaymentMethod paymentMethod, double cashTendered = 0}) async {
    if (_cartItems.isEmpty) return false;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final changeAmount = paymentMethod == PosPaymentMethod.cash ? (cashTendered - total).clamp(0.0, double.infinity) : 0.0;

      final result = await createPosOrderUseCase(CreatePosOrderParams(items: _cartItems, totalAmount: total, paymentMethod: paymentMethod, cashTendered: cashTendered, changeAmount: changeAmount));

      return result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
          _isProcessing = false;
          notifyListeners();
          return false;
        },
        (order) {
          _lastCompletedOrder = order;
          _cartItems.clear();
          _isProcessing = false;
          _loadPendingCount();
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Failed to complete order. Please try again.';
      _isProcessing = false;
      notifyListeners();
      debugPrint('[PosProvider] Complete order error: $e');
      return false;
    }
  }

  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Connection failed. Order saved locally and will sync when online.';
    }

    // Return original message if no mapping found
    return technicalError;
  }

  // ─────────────────────────────────────────────────────────
  // Order History
  // ─────────────────────────────────────────────────────────
  Future<void> loadTodayOrders() async {
    _isLoadingHistory = true;
    notifyListeners();

    final result = await getPosOrdersUseCase(NoParams());
    result.fold((failure) => _error = failure.message, (orders) => _todayOrders = orders);

    _isLoadingHistory = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // Sync
  // ─────────────────────────────────────────────────────────
  Future<void> _attemptSync() async {
    if (_isSyncing) return;
    final count = await repository.getPendingOrderCount();
    if (count == 0) return;

    _isSyncing = true;
    notifyListeners();

    await syncPosOrdersUseCase(NoParams());
    await _loadPendingCount();

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> manualSync() => _attemptSync();

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
