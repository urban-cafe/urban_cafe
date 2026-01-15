import 'package:flutter/foundation.dart';
import 'package:urban_cafe/domain/entities/order_entity.dart';
import 'package:urban_cafe/domain/entities/order_status.dart';
import 'package:urban_cafe/domain/usecases/orders/get_orders.dart';
import 'package:urban_cafe/domain/usecases/orders/update_order_status.dart';

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
  Stream<List<OrderEntity>> get ordersStream => getOrdersUseCase.repository.getOrdersStream();

  OrderProvider({required this.getOrdersUseCase, required this.updateOrderStatusUseCase});

  Future<void> fetchOrders({OrderStatus? status}) async {
    _isLoading = true;
    _error = null;
    _filterStatus = status;
    notifyListeners(); // Notify loading start

    final result = await getOrdersUseCase(GetOrdersParams(status: status));

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _orders = data;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    // Optimistic Update? Maybe risky. Let's do standard load.
    // Or we can just update the local list if success.

    final result = await updateOrderStatusUseCase(UpdateOrderStatusParams(orderId: orderId, status: newStatus));

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local list to reflect change immediately without re-fetch
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // Create new entity with updated status (Entities are immutable)
          // Actually, OrderEntity needs copyWith to be clean, but for now we can rebuild it
          // or just re-fetch. Re-fetching is safer for data consistency.
          fetchOrders(status: _filterStatus);
        }
        return true;
      },
    );
  }
}
