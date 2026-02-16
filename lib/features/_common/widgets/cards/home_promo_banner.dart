import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/responsive.dart';

import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class HomePromoBanner extends StatefulWidget {
  final List<MenuItemEntity> items;

  const HomePromoBanner({super.key, required this.items});

  @override
  State<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends State<HomePromoBanner> {
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listen to carousel position changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_onScrollChanged);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.hasContentDimensions && position.hasPixels) {
      final itemWidth = position.viewportDimension;
      final newIndex = (position.pixels / itemWidth).round().clamp(0, widget.items.length - 1);
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Landscape carousel: Reduced height, increased width
    final double height = Responsive.isCompact(context) ? 200 : 280;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = Responsive.isCompact(context) ? screenWidth * 0.92 : Responsive.width(context, 45); // Increased width
    final horizontalPadding = (screenWidth - itemWidth) / 2;

    return Column(
      children: [
        // Carousel
        SizedBox(
          height: height,
          child: CarouselView(
            controller: _controller,
            itemExtent: itemWidth,
            shrinkExtent: itemWidth * 0.9,
            itemSnapping: true,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: const RoundedRectangleBorder(), // Disable default shape, handle locally
            backgroundColor: Colors.transparent,
            onTap: (index) => context.push('/detail', extra: widget.items[index]),
            children: widget.items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Space between images (8px total)
                child: _PromoCard(item: entry.value, isActive: entry.key == _currentIndex),
              );
            }).toList(),
          ),
        ),

        // Page Indicators
        if (widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                final bool isSelected = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isSelected ? 24 : 6,
                  decoration: BoxDecoration(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(3)),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final MenuItemEntity item;
  final bool isActive;

  const _PromoCard({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Parallax-like effect (image stays cover)
            if (item.imageUrl != null)
              CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: cs.surfaceContainerHighest),
                errorWidget: (context, url, error) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary, cs.tertiary]),
                ),
                child: Icon(Icons.local_cafe, size: 80, color: Colors.white.withValues(alpha: 0.2)),
              ),

            // Gradient Overlay for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.8)],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),

            // Top Badge (Floating)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary, // Solid primary color for pop
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Special',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Tag (Glass effect)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      item.categoryName?.toUpperCase() ?? 'MENU',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    item.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceFormat.format(item.price),
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 4),
                        child: Text(
                          'Ks',
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
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
    );
  }
}
