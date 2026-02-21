import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/cdn_utils.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/_common/widgets/badges/menu_item_badges.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class MenuCard extends StatefulWidget {
  final MenuItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int index;

  const MenuCard({super.key, required this.item, this.onTap, this.onAddToCart, this.index = 0});

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
              borderRadius: AppRadius.xlAll,
              boxShadow: [
                BoxShadow(
                  color: _isPressed ? colorScheme.primary.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                  blurRadius: _isPressed ? 20 : 15,
                  offset: Offset(0, _isPressed ? 8 : 5),
                  spreadRadius: _isPressed ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.xlAll,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE
                    Hero(
                      tag: 'menu-${widget.item.id}',
                      child: ClipRRect(
                        borderRadius: AppRadius.lgAll,
                        child: Container(
                          width: 100,
                          height: 100,
                          color: colorScheme.surfaceContainerHighest,
                          child: CdnUtils.menuImageUrl(widget.item.imageUrl) != null
                              ? CachedNetworkImage(
                                  imageUrl: CdnUtils.menuImageUrl(widget.item.imageUrl)!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 300,
                                  fadeInDuration: const Duration(milliseconds: 300),
                                  placeholder: (_, _) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary.withValues(alpha: 0.5))),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => Icon(Icons.fastfood, size: 32, color: colorScheme.onSurfaceVariant),
                                )
                              : Icon(Icons.fastfood, size: 32, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // CONTENT
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17, color: colorScheme.onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.item.categoryName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.item.categoryName!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                MenuItemBadges(isMostPopular: widget.item.isMostPopular, isWeekendSpecial: widget.item.isWeekendSpecial),
                              ],
                            ),

                            // PRICE ROW
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  priceFormat.format(widget.item.price),
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary),
                                ),
                                const Spacer(),
                                if (!widget.item.isAvailable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: AppRadius.smAll),
                                    child: Text(
                                      'Sold Out',
                                      style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: widget.onAddToCart,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [colorScheme.primaryContainer, colorScheme.primaryContainer.withValues(alpha: 0.8)],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
                                    ),
                                    child: Icon(Icons.add, size: 18, color: colorScheme.onPrimaryContainer),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
