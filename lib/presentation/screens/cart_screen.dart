import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/domain/entities/order_type.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('my_cart'.tr()),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('cart_empty'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: item.menuItem.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.menuItem.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
                                      errorWidget: (_, _, _) => Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant),
                                    )
                                  : Container(
                                      color: colorScheme.surfaceContainerHighest,
                                      child: Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Note: ${item.notes}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  priceFormat.format(item.totalPrice),
                                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          // QUANTITY CONTROLS
                          Container(
                            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove, size: 18, color: colorScheme.onSurface),
                                  onPressed: () => cart.updateQuantity(item, item.quantity - 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                                Text('${item.quantity}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.add, size: 18, color: colorScheme.primary),
                                  onPressed: () => cart.updateQuantity(item, item.quantity + 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // CHECKOUT BAR
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ORDER TYPE SELECTOR
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Expanded(
                              child: _OrderTypeButton(type: OrderType.dineIn, isSelected: cart.orderType == OrderType.dineIn, onTap: () => cart.setOrderType(OrderType.dineIn)),
                            ),
                            Expanded(
                              child: _OrderTypeButton(type: OrderType.takeaway, isSelected: cart.orderType == OrderType.takeaway, onTap: () => cart.setOrderType(OrderType.takeaway)),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('total_price'.tr(), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                          Text(
                            priceFormat.format(cart.totalAmount),
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: cart.isPlacingOrder
                              ? null
                              : () async {
                                  final success = await cart.placeOrder();
                                  if (!context.mounted) return;

                                  if (success) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('order_placed'.tr()),
                                        content: Text('thank_you_order'.tr()),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              context.go('/orders'); // Navigate to Client Orders
                                            },
                                            child: Text('ok'.tr()),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cart.error ?? 'error'.tr()), backgroundColor: colorScheme.error));
                                  }
                                },
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                          child: cart.isPlacingOrder ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('place_order'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final OrderType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeButton({required this.type, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Map OrderType to localized string manually since we can't easily add tr() to enum directly without extension context
    String label = '';
    switch (type) {
      case OrderType.dineIn:
        label = 'dine_in'.tr();
        break;
      case OrderType.takeaway:
        label = 'takeaway'.tr();
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
