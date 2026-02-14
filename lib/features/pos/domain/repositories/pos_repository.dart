import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';

abstract class PosRepository {
  /// Create a POS order. If offline, queues locally for later sync.
  Future<Either<Failure, PosOrder>> createPosOrder({required List<CartItem> items, required double totalAmount, required PosPaymentMethod paymentMethod, double cashTendered, double changeAmount});

  /// Get today's POS orders.
  Future<Either<Failure, List<PosOrder>>> getPosOrders({DateTime? date});

  /// Sync all pending offline orders to Supabase.
  Future<Either<Failure, int>> syncOfflineOrders();

  /// Get count of pending offline orders.
  Future<int> getPendingOrderCount();
}
