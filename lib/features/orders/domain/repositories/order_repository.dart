import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders({OrderStatus? status});
  Future<Either<Failure, String>> createOrder({required List<CartItem> items, required double totalAmount, required OrderType type, int pointsRedeemed = 0});
  Stream<List<OrderEntity>> getOrdersStream({String? userId});
  Future<Either<Failure, void>> updateOrderStatus(String orderId, OrderStatus status);
  Future<Either<Failure, void>> updateOrderNotes(String orderId, String notes);
  Future<Either<Failure, Map<String, dynamic>>> getAdminAnalytics();
}
