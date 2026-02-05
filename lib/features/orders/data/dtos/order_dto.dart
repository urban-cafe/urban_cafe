import 'package:urban_cafe/features/menu/data/dtos/menu_item_dto.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_item.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';

class OrderDto {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String type;
  final String createdAt;
  final List<OrderItemDto> items;

  OrderDto({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.items,
  });

  factory OrderDto.fromMap(Map<String, dynamic> map) {
    return OrderDto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'] as String,
      type: map['type'] as String? ?? 'dineIn', // Default for legacy
      createdAt: map['created_at'] as String,
      items: (map['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItemDto.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      userId: userId,
      items: items.map((e) => e.toEntity()).toList(),
      totalAmount: totalAmount,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderStatus.pending,
      ),
      type: OrderType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => OrderType.dineIn,
      ),
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class OrderItemDto {
  final String id;
  final int quantity;
  final double priceAtOrder;
  final String? notes;
  final Map<String, dynamic> menuItemData;

  OrderItemDto({
    required this.id,
    required this.quantity,
    required this.priceAtOrder,
    this.notes,
    required this.menuItemData,
  });

  factory OrderItemDto.fromMap(Map<String, dynamic> map) {
    return OrderItemDto(
      id: map['id'] as String,
      quantity: map['quantity'] as int,
      priceAtOrder: (map['price_at_order'] as num).toDouble(),
      notes: map['notes'] as String?,
      // Assuming Supabase join returns nested object
      menuItemData: map['menu_items'] as Map<String, dynamic>,
    );
  }

  OrderItem toEntity() {
    return OrderItem(
      id: id,
      menuItem: MenuItemDto.fromMap(menuItemData).toEntity(),
      quantity: quantity,
      priceAtOrder: priceAtOrder,
      notes: notes,
    );
  }
}
