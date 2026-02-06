import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/animations.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/core/theme.dart';
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
      appBar: AppBar(title: Text('my_cart'.tr()), centerTitle: true, automaticallyImplyLeading: false, backgroundColor: colorScheme.surface, elevation: 0),
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
                    child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                      child: Icon(Icons.shopping_cart_outlined, size: 60, color: colorScheme.primary.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'cart_empty'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Add items to get started', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                    const SizedBox(height: 32),
                    FilledButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.restaurant_menu), label: Text('browse_menu'.tr())),
                  ],
                ),
              ),
            );
          }

          // Responsive layout
          final isExpanded = Responsive.isExpanded(context);
          final horizontalPadding = isExpanded ? 48.0 : 20.0;

          if (isExpanded) {
            // Two-column layout for expanded screens
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Cart Items
                      Expanded(
                        flex: 3,
                        child: _CartItemsList(cart: cart, priceFormat: priceFormat),
                      ),
                      const SizedBox(width: 32),
                      // Right: Checkout Panel
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _CheckoutPanel(cart: cart, auth: auth, priceFormat: priceFormat),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return FadeSlideAnimation(
                      index: index,
                      child: Dismissible(
                        key: ValueKey('${item.menuItem.id}_${item.selectedVariant?.id}_${item.notes}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => cart.removeFromCart(item),
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: colorScheme.error, borderRadius: AppRadius.xlAll),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: AppRadius.xlAll,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // IMAGE
                              ClipRRect(
                                borderRadius: AppRadius.lgAll,
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
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
                                    if (item.selectedVariant != null) Text('Size: ${item.selectedVariant!.name}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                    if (item.selectedAddons.isNotEmpty)
                                      Text('Add-ons: ${item.selectedAddons.map((e) => e.name).join(', ')}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: AppRadius.lgAll),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, size: 18, color: item.quantity > 1 ? colorScheme.primary : colorScheme.outline),
                                      onPressed: () => cart.updateQuantity(item, item.quantity - 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    ),
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
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
                        ),
                      ),
                    );
                  },
                ),
              ),

              // COMPACT CHECKOUT BAR
              _CompactCheckoutBar(cart: cart, auth: auth, priceFormat: priceFormat),
            ],
          );
        },
      ),
    );
  }
}

/// Compact checkout bar with expandable options
class _CompactCheckoutBar extends StatefulWidget {
  final CartProvider cart;
  final AuthProvider auth;
  final NumberFormat priceFormat;

  const _CompactCheckoutBar({required this.cart, required this.auth, required this.priceFormat});

  @override
  State<_CompactCheckoutBar> createState() => _CompactCheckoutBarState();
}

class _CompactCheckoutBarState extends State<_CompactCheckoutBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = widget.cart;
    final auth = widget.auth;

    return Container(
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
            // TOP: Arrow button (always visible at top of sheet)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_up, color: colorScheme.primary, size: 28),
                ),
              ),
            ),

            // EXPANDABLE OPTIONS
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              clipBehavior: Clip.hardEdge,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          // ORDER TYPE SELECTOR
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
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

                          // LOYALTY POINTS
                          if (auth.isClient && auth.loyaltyPoints > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${auth.loyaltyPoints} pts',
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.brown),
                                    ),
                                  ),
                                  Switch(
                                    value: cart.usePoints,
                                    activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                                    thumbColor: WidgetStateProperty.all(Colors.amber),
                                    onChanged: (value) => cart.toggleUsePoints(value, auth.loyaltyPoints),
                                  ),
                                ],
                              ),
                            ),

                          // PRICE BREAKDOWN (if points used)
                          if (cart.usePoints) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('subtotal'.tr(), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                Text(widget.priceFormat.format(cart.totalAmount), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'discount'.tr(),
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '-${widget.priceFormat.format(cart.discountAmount)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // BOTTOM: Total + Place Order
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('total_price'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      Text(
                        widget.priceFormat.format(cart.finalTotal),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom: Place Order Button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: cart.isPlacingOrder ? [colorScheme.outline, colorScheme.outline] : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: cart.isPlacingOrder ? null : [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: cart.isPlacingOrder ? null : () => _placeOrder(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: cart.isPlacingOrder
                                ? const Center(
                                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'place_order'.tr(),
                                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = widget.cart;
    final success = await cart.placeOrder();
    if (!context.mounted) return;

    if (success) {
      context.read<AuthProvider>().refreshProfile();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('order_placed'.tr()),
            content: Text('thank_you_order'.tr()),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cart.error ?? 'error'.tr()), backgroundColor: Theme.of(context).colorScheme.error));
    }
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

/// Extracted cart items list for responsive layout
class _CartItemsList extends StatelessWidget {
  final CartProvider cart;
  final NumberFormat priceFormat;

  const _CartItemsList({required this.cart, required this.priceFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: cart.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return FadeSlideAnimation(
          index: index,
          child: Dismissible(
            key: ValueKey('${item.menuItem.id}_${item.selectedVariant?.id}_${item.notes}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => cart.removeFromCart(item),
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: colorScheme.error, borderRadius: AppRadius.xlAll),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: AppRadius.xlAll,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    child: SizedBox(
                      width: 80,
                      height: 80,
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
                        if (item.selectedVariant != null) Text('Size: ${item.selectedVariant!.name}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        if (item.selectedAddons.isNotEmpty)
                          Text('Add-ons: ${item.selectedAddons.map((e) => e.name).join(', ')}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                  Container(
                    decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: AppRadius.lgAll),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: 18, color: item.quantity > 1 ? colorScheme.primary : colorScheme.outline),
                          onPressed: () => cart.updateQuantity(item, item.quantity - 1),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
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
            ),
          ),
        );
      },
    );
  }
}

/// Extracted checkout panel for responsive layout
class _CheckoutPanel extends StatelessWidget {
  final CartProvider cart;
  final AuthProvider auth;
  final NumberFormat priceFormat;

  const _CheckoutPanel({required this.cart, required this.auth, required this.priceFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('checkout'.tr(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Loyalty Points
        if (auth.isClient && auth.loyaltyPoints > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'redeem_points'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      Text('${auth.loyaltyPoints} available', style: theme.textTheme.bodySmall?.copyWith(color: Colors.brown)),
                    ],
                  ),
                ),
                Switch(
                  value: cart.usePoints,
                  activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(Colors.amber),
                  onChanged: (value) => cart.toggleUsePoints(value, auth.loyaltyPoints),
                ),
              ],
            ),
          ),

        // Order Type
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

        // Price Summary
        if (cart.usePoints) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('subtotal'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(priceFormat.format(cart.totalAmount), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'points_discount'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                '-${priceFormat.format(cart.discountAmount)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('total_price'.tr(), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            Text(
              priceFormat.format(cart.finalTotal),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Place Order Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cart.isPlacingOrder ? [colorScheme.outline, colorScheme.outline] : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: cart.isPlacingOrder ? null : [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: cart.isPlacingOrder ? null : () => _placeOrder(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: cart.isPlacingOrder
                    ? const Center(
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'place_order'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final success = await cart.placeOrder();
    if (!context.mounted) return;

    if (success) {
      context.read<AuthProvider>().refreshProfile();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('order_placed'.tr()),
            content: Text('thank_you_order'.tr()),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cart.error ?? 'error'.tr()), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }
}
