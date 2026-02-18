import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<OrderProvider>().orders.isEmpty) {
        context.read<OrderProvider>().fetchOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.read<AuthProvider>(); // Need auth to filter

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('my_orders'.tr(), style: Theme.of(context).textTheme.titleMedium), centerTitle: true, backgroundColor: colorScheme.surface, scrolledUnderElevation: 0),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchOrders(),
        child: StreamBuilder<List<OrderEntity>>(
          stream: orderProvider.getOrdersStream(userId: authProvider.currentUser?.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && orderProvider.orders.isEmpty) {
              return Skeletonizer(
                enabled: true,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, _) => Container(
                    height: 120,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.lgAll),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(child: Text('Error: ${snapshot.error}')),
                ),
              );
            }

            final orders = snapshot.data ?? orderProvider.orders;

            if (orders.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text('no_orders_yet'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _ClientOrderCard(order: order);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ClientOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _ClientOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.blue;
        break;
      case OrderStatus.ready:
        statusColor = Colors.green;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadius.lgAll,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'order_id'.tr()} #${order.id.substring(0, 6).toUpperCase()}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(timeago.format(order.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.xlAll,
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    // Manual mapping for status localization
                    _getLocalizedStatus(order.status),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Items Preview (First 2 items)
            ...order.items
                .take(2)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: AppRadius.xsAll),
                          child: Text('${item.quantity}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.menuItem.name, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                ),

            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+ ${order.items.length - 2} more items', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
              ),

            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(order.type.label == 'Dine-in' ? Icons.restaurant : Icons.shopping_bag_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_getLocalizedType(order.type), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending'.tr();
      case OrderStatus.preparing:
        return 'preparing'.tr();
      case OrderStatus.ready:
        return 'ready'.tr();
      case OrderStatus.completed:
        return 'completed'.tr();
      case OrderStatus.cancelled:
        return 'cancelled'.tr();
    }
  }

  String _getLocalizedType(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'dine_in'.tr();
      case OrderType.takeaway:
        return 'takeaway'.tr();
    }
  }
}
