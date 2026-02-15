import 'package:flutter/foundation.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_orders.dart';
import 'package:urban_cafe/features/orders/domain/usecases/update_order_status.dart';

class OrderProvider extends ChangeNotifier {
  final GetOrders getOrdersUseCase;
  final UpdateOrderStatus updateOrderStatusUseCase;

  List<OrderEntity> _orders = [];
  List<OrderEntity> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  OrderStatus? _filterStatus;
  OrderStatus? get filterStatus => _filterStatus;

  // Stream Support
  Stream<List<OrderEntity>> getOrdersStream({String? userId}) => getOrdersUseCase.repository.getOrdersStream(userId: userId);

  OrderProvider({required this.getOrdersUseCase, required this.updateOrderStatusUseCase});

  Future<void> fetchOrders({OrderStatus? status}) async {
    _isLoading = true;
    _error = null;
    _filterStatus = status;
    notifyListeners(); // Notify loading start

    try {
      final result = await getOrdersUseCase(GetOrdersParams(status: status));

      result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
          _isLoading = false;
          notifyListeners();
        },
        (data) {
          _orders = data;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to load orders. Please try again.';
      _isLoading = false;
      notifyListeners();
      debugPrint('[OrderProvider] Fetch orders error: $e');
    }
  }

  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Connection failed. Please check your internet and try again.';
    }

    // Return original message if no mapping found
    return technicalError;
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      final result = await updateOrderStatusUseCase(UpdateOrderStatusParams(orderId: orderId, status: newStatus));

      return result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
          notifyListeners();
          return false;
        },
        (_) {
          // Update local list to reflect change immediately without re-fetch
          final index = _orders.indexWhere((o) => o.id == orderId);
          if (index != -1) {
            // Re-fetch for data consistency
            fetchOrders(status: _filterStatus);
          }
          return true;
        },
      );
    } catch (e) {
      _error = 'Failed to update order status. Please try again.';
      notifyListeners();
      debugPrint('[OrderProvider] Update status error: $e');
      return false;
    }
  }
}
