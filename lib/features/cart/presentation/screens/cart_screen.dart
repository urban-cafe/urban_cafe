import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/orders/domain/entities/order_type.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('my_cart'.tr()),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 60,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'cart_empty'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Browse Menu'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 80)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: item.menuItem.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: item.menuItem.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        errorWidget: (_, _, _) => Icon(
                                          Icons.fastfood,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Container(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.fastfood,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.selectedVariant != null)
                                    Text(
                                      'Size: ${item.selectedVariant!.name}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  if (item.selectedAddons.isNotEmpty)
                                    Text(
                                      'Add-ons: ${item.selectedAddons.map((e) => e.name).join(', ')}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  if (item.notes != null &&
                                      item.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${item.notes}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    priceFormat.format(item.totalPrice),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            // QUANTITY CONTROLS with animation
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove,
                                      size: 18,
                                      color: item.quantity > 1
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                    ),
                                    onPressed: () => cart.updateQuantity(
                                      item,
                                      item.quantity - 1,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: () => cart.updateQuantity(
                                      item,
                                      item.quantity + 1,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOYALTY POINTS REDEMPTION
                      if (auth.isClient && auth.loyaltyPoints > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Redeem Points',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown,
                                          ),
                                    ),
                                    Text(
                                      '${auth.loyaltyPoints} available',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.brown),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: cart.usePoints,
                                activeTrackColor: Colors.amber.withValues(
                                  alpha: 0.5,
                                ),
                                thumbColor: WidgetStateProperty.all(
                                  Colors.amber,
                                ),
                                onChanged: (value) => cart.toggleUsePoints(
                                  value,
                                  auth.loyaltyPoints,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ORDER TYPE SELECTOR
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _OrderTypeButton(
                                type: OrderType.dineIn,
                                isSelected: cart.orderType == OrderType.dineIn,
                                onTap: () =>
                                    cart.setOrderType(OrderType.dineIn),
                              ),
                            ),
                            Expanded(
                              child: _OrderTypeButton(
                                type: OrderType.takeaway,
                                isSelected:
                                    cart.orderType == OrderType.takeaway,
                                onTap: () =>
                                    cart.setOrderType(OrderType.takeaway),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (cart.usePoints) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              priceFormat.format(cart.totalAmount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Points Discount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '-${priceFormat.format(cart.discountAmount)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'total_price'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            priceFormat.format(cart.finalTotal),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: cart.isPlacingOrder
                                  ? [colorScheme.outline, colorScheme.outline]
                                  : [
                                      colorScheme.primary,
                                      colorScheme.primary.withValues(
                                        alpha: 0.85,
                                      ),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: cart.isPlacingOrder
                                ? null
                                : [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: cart.isPlacingOrder
                                  ? null
                                  : () async {
                                      final success = await cart.placeOrder();
                                      if (!context.mounted) return;

                                      if (success) {
                                        if (context.mounted) {
                                          context
                                              .read<AuthProvider>()
                                              .refreshProfile();
                                        }

                                        if (context.mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('order_placed'.tr()),
                                              content: Text(
                                                'thank_you_order'.tr(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    context.go('/orders');
                                                  },
                                                  child: Text('ok'.tr()),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              cart.error ?? 'error'.tr(),
                                            ),
                                            backgroundColor: colorScheme.error,
                                          ),
                                        );
                                      }
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                child: cart.isPlacingOrder
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'place_order'.tr(),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
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

  const _OrderTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
