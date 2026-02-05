import 'package:equatable/equatable.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class OrderItem extends Equatable {
  final String id;
  final MenuItemEntity menuItem;
  final int quantity;
  final double priceAtOrder; // Price might change later, so store snapshot
  final String? notes;

  const OrderItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.priceAtOrder,
    this.notes,
  });

  double get totalPrice => priceAtOrder * quantity;

  @override
  List<Object?> get props => [id, menuItem, quantity, priceAtOrder, notes];
}
