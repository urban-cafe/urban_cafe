import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: _isPressed ? cs.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                blurRadius: _isPressed ? 20 : 15,
                offset: Offset(0, _isPressed ? 8 : 6),
                spreadRadius: _isPressed ? 2 : 0,
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
                        tag: 'menu-grid-${widget.item.id}',
                        child: Container(
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest),
                          child: widget.item.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.item.imageUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  placeholder: (_, _) => Container(
                                    color: cs.surfaceContainerHighest,
                                    child: Center(child: Icon(Icons.local_cafe, color: cs.outlineVariant.withValues(alpha: 0.5), size: 32)),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    color: cs.surfaceContainerHighest,
                                    child: Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40),
                                  ),
                                )
                              : Center(child: Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40)),
                        ),
                      ),

                      // Gradient overlay for depth
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1)]),
                          ),
                        ),
                      ),

                      // Rating Badge with glassmorphism
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Popular badge
                      if (widget.item.isMostPopular)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: const Text(
                              '🔥 HOT',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // CONTENT SECTION
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.item.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Category
                        Text(widget.item.categoryName ?? 'Coffee', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline, fontSize: 12)),

                        const Spacer(),

                        // Price & Add Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              priceFormat.format(widget.item.price),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16),
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
    );
  }
}
