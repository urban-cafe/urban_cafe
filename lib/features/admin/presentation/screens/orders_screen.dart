import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_entity.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_status.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('order_management'.tr(), style: Theme.of(context).textTheme.titleMedium),
        actions: [
          // Filter Button (For Date/Payment/Type)
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showAdvancedFilters(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<OrderProvider>().fetchOrders()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showManualOrderDialog(context), label: Text('manual_order'.tr()), icon: const Icon(Icons.add)),
      body: Column(
        children: [
          // Filter Chips (Status)
          SizedBox(
            height: 60,
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _FilterChip(label: 'all'.tr(), isSelected: provider.filterStatus == null, onSelected: () => provider.fetchOrders(status: null)),
                    const SizedBox(width: 8),
                    ...OrderStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: _getLocalizedStatus(status),
                          isSelected: provider.filterStatus == status,
                          onSelected: () => provider.fetchOrders(status: status),
                          color: _getStatusColor(status, colorScheme),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => orderProvider.fetchOrders(),
              child: StreamBuilder<List<OrderEntity>>(
                stream: orderProvider.getOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && orderProvider.orders.isEmpty) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        itemCount: 5,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => const Card(child: SizedBox(height: 150)),
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

                  var orders = snapshot.data ?? orderProvider.orders;

                  // Apply local filtering if stream returns all
                  // The stream currently returns ALL orders unless filtered by UserID.
                  // Admin needs to filter by status locally or via stream params (if implemented).
                  // Our stream implementation fetches ALL. So we filter here.
                  if (orderProvider.filterStatus != null) {
                    orders = orders.where((o) => o.status == orderProvider.filterStatus).toList();
                  }

                  if (orders.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outlineVariant),
                              const SizedBox(height: 16),
                              Text('no_orders_yet'.tr(), style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _OrderCard(order: orders[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text("${"filter".tr()} (Date, Payment, Staff) - Coming Soon"), const SizedBox(height: 24)]),
      ),
    );
  }

  void _showManualOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('manual_order'.tr()),
        content: const Text('Create walk-in order feature coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr()))],
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

  Color _getStatusColor(OrderStatus status, ColorScheme cs) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return cs.outline;
      case OrderStatus.cancelled:
        return cs.error;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = color ?? colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: baseColor.withValues(alpha: 0.2),
      checkmarkColor: baseColor,
      labelStyle: TextStyle(color: isSelected ? baseColor : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
        side: BorderSide(color: isSelected ? baseColor : colorScheme.outlineVariant),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = timeago.format(order.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.id.substring(0, 8).toUpperCase()}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 24),

            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: AppRadius.xsAll),
                      child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.menuItem.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (item.notes != null) Text('Note: ${item.notes}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text('Total: \$${order.totalAmount.toStringAsFixed(0)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) _ActionButtons(order: order),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case OrderStatus.preparing:
        color = Colors.blue;
        icon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.completed:
        color = colorScheme.outline;
        icon = Icons.done_all;
        break;
      case OrderStatus.cancelled:
        color = colorScheme.error;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getLocalizedStatus(status),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
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
}

class _ActionButtons extends StatelessWidget {
  final OrderEntity order;

  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    // Define next logical step
    OrderStatus? nextStatus;
    String label = '';

    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.preparing;
        label = 'accept'.tr();
        break;
      case OrderStatus.preparing:
        nextStatus = OrderStatus.ready;
        label = 'ready'.tr();
        break;
      case OrderStatus.ready:
        nextStatus = OrderStatus.completed;
        label = 'complete'.tr();
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (order.status == OrderStatus.pending)
          TextButton(
            onPressed: () => provider.updateStatus(order.id, OrderStatus.cancelled),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('reject'.tr()),
          ),
        const SizedBox(width: 8),
        FilledButton(onPressed: () => provider.updateStatus(order.id, nextStatus!), child: Text(label)),
      ],
    );
  }
}
