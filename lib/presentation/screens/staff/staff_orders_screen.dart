import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:urban_cafe/domain/entities/order_entity.dart';
import 'package:urban_cafe/domain/entities/order_status.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';
import 'package:urban_cafe/presentation/providers/order_provider.dart';

class StaffOrdersScreen extends StatelessWidget {
  const StaffOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('live_kitchen_orders'.tr()),
        actions: [
          // Preparation Timer Toggle or Status could go here
          IconButton(icon: const Icon(Icons.print), onPressed: () => _showPrintDialog(context)),
          // Removed redundant Profile Icon (now in Bottom Nav)
        ],
      ),
      body: StreamBuilder<List<OrderEntity>>(
        stream: provider.ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Skeletonizer(
              enabled: true,
              child: ListView.builder(
                itemCount: 5,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) => const Card(child: SizedBox(height: 150)),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          // Filter out completed/cancelled for Kitchen View (Focus on Active)
          final activeOrders = orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text('no_items_found'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _StaffOrderCard(order: activeOrders[index]);
            },
          );
        },
      ),
    );
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Printer Status'),
        content: const Text('Kitchen Printer: Connected\nReceipt Printer: Connected'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _StaffOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = timeago.format(order.createdAt);

    // Priority Logic: If older than 15 mins and still pending/preparing -> Urgent
    final isUrgent = DateTime.now().difference(order.createdAt).inMinutes > 15;

    return Card(
      elevation: 4,
      color: isUrgent ? colorScheme.errorContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent ? BorderSide(color: colorScheme.error, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isUrgent)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.warning, color: colorScheme.error),
                      ),
                    Text('#${order.id.substring(0, 6).toUpperCase()}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                _StatusChip(status: order.status),
              ],
            ),
            Text('$timeStr • ${_getLocalizedType(order.type)}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const Divider(height: 24),

            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.inverseSurface, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(color: colorScheme.onInverseSurface, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.menuItem.name, style: theme.textTheme.titleMedium),
                          if (item.notes != null)
                            Text(
                              'NOTE: ${item.notes}',
                              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Staff Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'Add Internal Note',
                  onPressed: () {
                    // Show dialog to add note
                  },
                ),
                const SizedBox(width: 8),
                _StaffActionButtons(order: order),
              ],
            ),
          ],
        ),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.preparing:
        color = Colors.blue;
        break;
      case OrderStatus.ready:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    String label = '';
    switch (status) {
      case OrderStatus.pending:
        label = 'pending'.tr();
        break;
      case OrderStatus.preparing:
        label = 'preparing'.tr();
        break;
      case OrderStatus.ready:
        label = 'ready'.tr();
        break;
      case OrderStatus.completed:
        label = 'completed'.tr();
        break;
      case OrderStatus.cancelled:
        label = 'cancelled'.tr();
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      side: BorderSide.none,
    );
  }
}

class _StaffActionButtons extends StatelessWidget {
  final OrderEntity order;
  const _StaffActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: () => provider.updateStatus(order.id, OrderStatus.cancelled),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reject'.tr()),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: () => provider.updateStatus(order.id, OrderStatus.preparing), icon: const Icon(Icons.play_arrow), label: Text('start_prep'.tr())),
        ],
      );
    } else if (order.status == OrderStatus.preparing) {
      return FilledButton.icon(
        onPressed: () => provider.updateStatus(order.id, OrderStatus.ready),
        icon: const Icon(Icons.check),
        style: FilledButton.styleFrom(backgroundColor: Colors.green),
        label: Text('mark_ready'.tr()),
      );
    } else if (order.status == OrderStatus.ready) {
      return FilledButton.icon(onPressed: () => provider.updateStatus(order.id, OrderStatus.completed), icon: const Icon(Icons.done_all), label: Text('complete'.tr()));
    }

    return const SizedBox.shrink();
  }
}
