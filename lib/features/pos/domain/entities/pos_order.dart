import 'package:equatable/equatable.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_item.dart';

enum PosPaymentMethod {
  cash,
  card;

  String get label {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.card:
        return 'Card';
    }
  }
}

class PosOrder extends Equatable {
  final String? id;
  final String offlineId;
  final String staffId;
  final List<OrderItem> items;
  final double totalAmount;
  final PosPaymentMethod paymentMethod;
  final double cashTendered;
  final double changeAmount;
  final String status; // completed, cancelled
  final DateTime createdAt;
  final bool isSynced;

  const PosOrder({
    this.id,
    required this.offlineId,
    required this.staffId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashTendered = 0,
    this.changeAmount = 0,
    this.status = 'completed',
    required this.createdAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [id, offlineId, staffId, totalAmount, paymentMethod, status, createdAt, isSynced];
}
