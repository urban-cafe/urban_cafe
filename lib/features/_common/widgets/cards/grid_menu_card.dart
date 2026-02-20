import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/core/cdn_utils.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/features/_common/widgets/badges/menu_item_badges.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class GridMenuCard extends StatefulWidget {
  final MenuItemEntity item;
  final int index;

  const GridMenuCard({super.key, required this.item, this.index = 0});

  @override
  State<GridMenuCard> createState() => _GridMenuCardState();
}

class _GridMenuCardState extends State<GridMenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    context.push('/detail', extra: widget.item);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _addToCart() {
    // Navigate to detail if item has variants/addons — user must choose
    if (widget.item.variants.isNotEmpty || widget.item.addons.isNotEmpty) {
      context.push('/detail', extra: widget.item);
      return;
    }
    context.read<CartProvider>().addToCart(widget.item);
    showAppSnackBar(context, 'Added to Cart Successfully');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : Colors.white,
            borderRadius: AppRadius.xlAll,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.06 : 0.05),
                blurRadius: _isPressed ? 10 : 8,
                offset: Offset(0, _isPressed ? 3 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.xlAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE SECTION
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with gradient overlay
                      Hero(
                        tag: 'menu-grid-${widget.item.id}-${widget.index}',
                        child: Container(
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest),
                          child: CdnUtils.menuImageUrl(widget.item.imageUrl) != null
                              ? CachedNetworkImage(
                                  imageUrl: CdnUtils.menuImageUrl(widget.item.imageUrl)!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  placeholder: (_, _) => Container(
                                    color: cs.surfaceContainerHighest,
                                    child: Center(
                                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary.withValues(alpha: 0.5))),
                                    ),
                                  ),
                                  errorWidget: (_, url, error) {
                                    debugPrint('❌ Image Load Error: $url | Exception: $error');
                                    return Container(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40),
                                    );
                                  },
                                )
                              : Center(child: Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40)),
                        ),
                      ),

                      // Popular badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: MenuItemBadges(isMostPopular: widget.item.isMostPopular, isWeekendSpecial: widget.item.isWeekendSpecial),
                      ),
                    ],
                  ),
                ),

                // CONTENT SECTION
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        widget.item.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Category
                      Text(
                        widget.item.categoryName ?? 'Coffee',
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            priceFormat.format(widget.item.price),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: cs.primary),
                          ),
                          const Spacer(),
                          if (!widget.item.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: AppRadius.smAll),
                              child: Text(
                                'Sold Out',
                                style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          else if (!isGuest)
                            GestureDetector(
                              onTap: _addToCart,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                                child: Icon(Icons.add, size: 17, color: cs.onPrimaryContainer),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
