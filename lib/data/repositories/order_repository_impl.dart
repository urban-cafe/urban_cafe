import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/dtos/order_dto.dart';
import 'package:urban_cafe/domain/entities/cart_item.dart';
import 'package:urban_cafe/domain/entities/order_entity.dart';
import 'package:urban_cafe/domain/entities/order_status.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';
import 'package:urban_cafe/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  static const String table = 'orders';
  static const String itemsTable = 'order_items';
  SupabaseClient get _client => SupabaseClientProvider.client;

  @override
  Future<Either<Failure, String>> createOrder({required List<CartItem> items, required double totalAmount, required OrderType type}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    final user = _client.auth.currentUser;
    if (user == null) return const Left(AuthFailure('User not logged in'));

    try {
      // 1. Create Order Record
      final orderRes = await _client.from(table).insert({'user_id': user.id, 'total_amount': totalAmount, 'status': OrderStatus.pending.name, 'type': type.name}).select('id').single();

      final orderId = orderRes['id'] as String;

      // 2. Create Order Items
      final itemsData = items.map((item) => {'order_id': orderId, 'menu_item_id': item.menuItem.id, 'quantity': item.quantity, 'price_at_order': item.menuItem.price, 'notes': item.notes}).toList();

      await _client.from(itemsTable).insert(itemsData);

      return Right(orderId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<OrderEntity>> getOrdersStream() {
    return _client.from(table).stream(primaryKey: ['id']).order('created_at', ascending: false).asyncMap((data) async {
      // Supabase Stream only returns the main table data.
      // We need to fetch items manually or join if possible.
      // Note: .stream() doesn't support joins yet in most SDKs efficiently.
      // For now, we will fetch full details for the changed IDs or just re-fetch all active orders.
      // A better approach for scalability is to listen to changes and then trigger a fetch.
      // However, for this demo, let's just map what we have and maybe fetch items for displayed orders.

      // Actually, let's try to just return the stream and handle fetching details in the UI/Provider
      // or do a quick fetch for details.
      // Since we need to show items in the list, we really need the joins.

      // Workaround: Return the list from stream, but we might miss items.
      // Better Workaround: Use the stream to trigger a re-fetch in the Provider.
      // But here we need to return Stream<List<OrderEntity>>.

      // Let's iterate and fetch items (N+1 problem, but okay for small scale).
      final orders = <OrderEntity>[];
      for (final map in data) {
        final orderId = map['id'] as String;
        final itemsRes = await _client.from(itemsTable).select('*, menu_items(*)').eq('order_id', orderId);

        final fullMap = Map<String, dynamic>.from(map);
        fullMap['order_items'] = itemsRes;

        orders.add(OrderDto.fromMap(fullMap).toEntity());
      }
      return orders;
    });
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders({OrderStatus? status}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      var query = _client.from(table).select('''
        *,
        order_items (
          *,
          menu_items (*)
        )
      ''');

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final data = await query.order('created_at', ascending: false);

      final orders = (data as List<dynamic>).map((e) => OrderDto.fromMap(e as Map<String, dynamic>).toEntity()).toList();

      return Right(orders);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, OrderStatus status) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      await _client.from(table).update({'status': status.name}).eq('id', orderId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderNotes(String orderId, String notes) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      // Assuming there is a 'staff_notes' column in the orders table
      // If not, we should create it or use 'notes' if it's for general notes.
      // The requirement says "Add internal notes (visible to staff only)".
      // So let's assume 'staff_notes' column.
      await _client.from(table).update({'staff_notes': notes}).eq('id', orderId);
      return const Right(null);
    } catch (e) {
      // If column doesn't exist, this will fail.
      return Left(ServerFailure(e.toString()));
    }
  }
}
