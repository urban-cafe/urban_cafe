import 'package:equatable/equatable.dart';
import 'package:urban_cafe/domain/entities/order_item.dart';
import 'package:urban_cafe/domain/entities/order_status.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId; // Or "Guest"
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final OrderType type;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, items, totalAmount, status, type, createdAt];
}
