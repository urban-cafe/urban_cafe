import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/orders/data/dtos/order_dto.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';
import 'package:urban_cafe/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  static const String table = 'orders';
  static const String itemsTable = 'order_items';

  final SupabaseClient _client;

  OrderRepositoryImpl(this._client);

  @override
  Future<Either<Failure, String>> createOrder({required List<CartItem> items, required double totalAmount, required OrderType type, int pointsRedeemed = 0}) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    final user = _client.auth.currentUser;
    if (user == null) return const Left(AuthFailure('User not logged in'));

    try {
      // 1. Create Order Record
      final orderRes = await _client
          .from(table)
          .insert({'user_id': user.id, 'total_amount': totalAmount, 'status': OrderStatus.pending.name, 'type': type.name, 'points_redeemed': pointsRedeemed})
          .select('id')
          .single();

      final orderId = orderRes['id'] as String;

      // 2. Create Order Items
      final itemsData = items.map((item) {
        // Prepare customization data (JSONB)
        final customization = {
          'variant': item.selectedVariant != null ? {'id': item.selectedVariant!.id, 'name': item.selectedVariant!.name, 'price_adjustment': item.selectedVariant!.priceAdjustment} : null,
          'addons': item.selectedAddons.map((addon) => {'id': addon.id, 'name': addon.name, 'price': addon.price}).toList(),
        };

        return {
          'order_id': orderId,
          'menu_item_id': item.menuItem.id,
          'quantity': item.quantity,
          'price_at_order': item.unitPrice, // Use unit price which includes adjustments
          'notes': item.notes,
          'customization': customization, // Assuming we add this JSONB column
        };
      }).toList();

      await _client.from(itemsTable).insert(itemsData);

      return Right(orderId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<OrderEntity>> getOrdersStream({String? userId}) {
    // Listen to changes in the 'orders' table
    var builder = _client.from(table).stream(primaryKey: ['id']);

    // Note: Supabase stream filters are limited.
    // eq filter MUST be applied BEFORE order/limit etc in newer SDKs, but for stream() it works differently.
    // Actually, the `eq` method is available on `SupabaseStreamFilterBuilder` which is returned by `stream()`.
    // However, chaining order() returns `SupabaseStreamBuilder` which might not have `eq`.
    // We should apply filters first.

    SupabaseStreamBuilder query;
    if (userId != null) {
      query = builder.eq('user_id', userId).order('created_at', ascending: false);
    } else {
      query = builder.order('created_at', ascending: false);
    }

    return query.asyncMap((data) async {
      // Supabase Stream only returns the main table data.
      // We need to fetch items manually to get full details (items, customizations).

      if (data.isEmpty) return [];

      final orderIds = data.map((e) => e['id'] as String).toList();

      // Fetch items for these orders
      final itemsRes = await _client.from(itemsTable).select('*, menu_items(*)').inFilter('order_id', orderIds);

      final itemsList = itemsRes as List<dynamic>;

      // Map orders with their items
      final orders = data.map((map) {
        final orderId = map['id'] as String;
        final orderItems = itemsList.where((item) => item['order_id'] == orderId).toList();

        final fullMap = Map<String, dynamic>.from(map);
        fullMap['order_items'] = orderItems;

        return OrderDto.fromMap(fullMap).toEntity();
      }).toList();

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

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAdminAnalytics() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));
    try {
      final res = await _client.rpc('get_admin_analytics');
      return Right(res as Map<String, dynamic>);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
