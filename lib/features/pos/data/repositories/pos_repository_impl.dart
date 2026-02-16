import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/app_exception.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/pos/data/datasources/pos_local_datasource.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';
import 'package:uuid/uuid.dart';

class PosRepositoryImpl implements PosRepository {
  static const String _ordersTable = 'orders';
  static const String _itemsTable = 'order_items';

  final SupabaseClient _client;
  final PosLocalDatasource _localDatasource;
  final Connectivity _connectivity;
  final Uuid _uuid = const Uuid();

  PosRepositoryImpl(this._client, this._localDatasource, this._connectivity);

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Future<Either<Failure, PosOrder>> createPosOrder({
    required List<CartItem> items,
    required double totalAmount,
    required PosPaymentMethod paymentMethod,
    double cashTendered = 0,
    double changeAmount = 0,
  }) async {
    if (!Env.isConfigured) return const Left(ServerFailure('App not configured.', code: 'env_not_configured'));
    final user = _client.auth.currentUser;
    if (user == null) return const Left(AuthFailure('Please sign in to continue.', code: 'auth_not_logged_in'));

    final offlineId = _uuid.v4();
    final now = DateTime.now();

    // Prepare item data for both local and remote storage
    final itemsData = items.map((item) {
      final customization = {
        'variant': item.selectedVariant != null ? {'id': item.selectedVariant!.id, 'name': item.selectedVariant!.name, 'price_adjustment': item.selectedVariant!.priceAdjustment} : null,
        'addons': item.selectedAddons.map((addon) => {'id': addon.id, 'name': addon.name, 'price': addon.price}).toList(),
      };
      return {'menu_item_id': item.menuItem.id, 'menu_item_name': item.menuItem.name, 'quantity': item.quantity, 'price_at_order': item.unitPrice, 'notes': item.notes, 'customization': customization};
    }).toList();

    final order = PosOrder(
      offlineId: offlineId,
      staffId: user.id,
      items: const [],
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      cashTendered: cashTendered,
      changeAmount: changeAmount,
      createdAt: now,
      isSynced: false,
    );

    final online = await _isOnline();

    if (online) {
      try {
        final orderRes = await _client
            .from(_ordersTable)
            .insert({
              'user_id': user.id,
              'staff_id': user.id,
              'total_amount': totalAmount,
              'status': 'completed',
              'type': 'dineIn',
              'source': 'pos',
              'payment_method': paymentMethod.name,
              'cash_tendered': cashTendered,
              'change_amount': changeAmount,
              'offline_id': offlineId,
            })
            .select('id')
            .single();

        final orderId = orderRes['id'] as String;

        final remoteItems = itemsData.map((item) {
          final m = Map<String, dynamic>.from(item);
          m['order_id'] = orderId;
          m.remove('menu_item_name');
          return m;
        }).toList();

        await _client.from(_itemsTable).insert(remoteItems);

        return Right(
          PosOrder(
            id: orderId,
            offlineId: offlineId,
            staffId: user.id,
            items: const [],
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            cashTendered: cashTendered,
            changeAmount: changeAmount,
            createdAt: now,
            isSynced: true,
          ),
        );
      } catch (e) {
        // Network failed mid-request — fall through to offline save
        await _saveLocally(
          offlineId: offlineId,
          staffId: user.id,
          totalAmount: totalAmount,
          paymentMethod: paymentMethod.name,
          cashTendered: cashTendered,
          changeAmount: changeAmount,
          itemsData: itemsData,
          createdAt: now,
        );
        return Right(order);
      }
    } else {
      // Offline — save locally
      await _saveLocally(
        offlineId: offlineId,
        staffId: user.id,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod.name,
        cashTendered: cashTendered,
        changeAmount: changeAmount,
        itemsData: itemsData,
        createdAt: now,
      );
      return Right(order);
    }
  }

  Future<void> _saveLocally({
    required String offlineId,
    required String staffId,
    required double totalAmount,
    required String paymentMethod,
    required double cashTendered,
    required double changeAmount,
    required List<Map<String, dynamic>> itemsData,
    required DateTime createdAt,
  }) async {
    await _localDatasource.insertPendingOrder(
      offlineId: offlineId,
      staffId: staffId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      cashTendered: cashTendered,
      changeAmount: changeAmount,
      itemsJson: itemsData,
      createdAt: createdAt,
    );
  }

  @override
  Future<Either<Failure, List<PosOrder>>> getPosOrders({DateTime? date}) async {
    if (!Env.isConfigured) return const Left(ServerFailure('App not configured.', code: 'env_not_configured'));

    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _client
          .from(_ordersTable)
          .select('*')
          .eq('source', 'pos')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      final orders = (data as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        return PosOrder(
          id: map['id'] as String,
          offlineId: (map['offline_id'] as String?) ?? '',
          staffId: (map['staff_id'] as String?) ?? (map['user_id'] as String),
          items: const [],
          totalAmount: (map['total_amount'] as num).toDouble(),
          paymentMethod: PosPaymentMethod.values.firstWhere((m) => m.name == (map['payment_method'] as String? ?? 'cash'), orElse: () => PosPaymentMethod.cash),
          cashTendered: (map['cash_tendered'] as num?)?.toDouble() ?? 0,
          changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0,
          status: map['status'] as String? ?? 'completed',
          createdAt: DateTime.parse(map['created_at'] as String),
          isSynced: true,
        );
      }).toList();

      return Right(orders);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> syncOfflineOrders() async {
    if (!Env.isConfigured) return const Left(ServerFailure('App not configured.', code: 'env_not_configured'));

    final online = await _isOnline();
    if (!online) return const Left(NetworkFailure('No internet connection.', code: 'offline'));

    try {
      final pendingOrders = await _localDatasource.getPendingOrders();
      int syncedCount = 0;

      for (final orderData in pendingOrders) {
        final offlineId = orderData['offline_id'] as String;
        final staffId = orderData['staff_id'] as String;
        final totalAmount = (orderData['total_amount'] as num).toDouble();
        final paymentMethod = orderData['payment_method'] as String;
        final cashTendered = (orderData['cash_tendered'] as num?)?.toDouble() ?? 0;
        final changeAmount = (orderData['change_amount'] as num?)?.toDouble() ?? 0;
        final itemsJson = orderData['items_json'] as List<dynamic>;
        final createdAt = orderData['created_at'] as String;

        try {
          // Check if already synced (dedup via offline_id unique constraint)
          final orderRes = await _client
              .from(_ordersTable)
              .insert({
                'user_id': staffId,
                'staff_id': staffId,
                'total_amount': totalAmount,
                'status': 'completed',
                'type': 'dineIn',
                'source': 'pos',
                'payment_method': paymentMethod,
                'cash_tendered': cashTendered,
                'change_amount': changeAmount,
                'offline_id': offlineId,
                'created_at': createdAt,
              })
              .select('id')
              .single();

          final orderId = orderRes['id'] as String;

          final remoteItems = (itemsJson).map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            m['order_id'] = orderId;
            m.remove('menu_item_name');
            return m;
          }).toList();

          await _client.from(_itemsTable).insert(remoteItems);
          await _localDatasource.markAsSynced(offlineId);
          syncedCount++;
        } catch (e) {
          // If unique constraint violation, it's already synced
          if (e is PostgrestException && e.code == '23505') {
            await _localDatasource.markAsSynced(offlineId);
            syncedCount++;
          }
          // Otherwise skip this order and try next
        }
      }

      // Cleanup synced orders
      await _localDatasource.deleteSyncedOrders();
      return Right(syncedCount);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<int> getPendingOrderCount() async {
    return _localDatasource.getPendingCount();
  }
}
