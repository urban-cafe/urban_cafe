import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/responsive.dart';

import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class HomePromoBanner extends StatefulWidget {
  final List<MenuItemEntity> items;
  final bool isLoading;

  const HomePromoBanner({super.key, required this.items, this.isLoading = false});

  @override
  State<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends State<HomePromoBanner> {
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;
  double _lastItemWidth = 1.0;

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
      final newIndex = (position.pixels / _lastItemWidth).round().clamp(0, widget.items.length - 1);
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = Responsive.isCompact(context) ? 180 : 260;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = Responsive.isCompact(context) ? screenWidth * 0.80 : Responsive.width(context, 45);
    _lastItemWidth = itemWidth;

    // ── Skeleton Loading State ──────────────────────────────────────────────
    if (widget.isLoading || widget.items.isEmpty) {
      return Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(baseColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), highlightColor: Theme.of(context).colorScheme.surface),
        child: SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, _) => SizedBox(
              width: itemWidth,
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
                child: Stack(
                  children: [
                    // Badge chip skeleton
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        height: 28,
                        width: 80,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                    // Bottom content skeleton
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category tag
                          Container(
                            height: 20,
                            width: 70,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                          ),
                          const SizedBox(height: 8),
                          // Title line 1
                          Container(
                            height: 22,
                            width: itemWidth * 0.7,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          ),
                          const SizedBox(height: 6),
                          // Title line 2
                          Container(
                            height: 22,
                            width: itemWidth * 0.5,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          ),
                          const SizedBox(height: 12),
                          // Price
                          Container(
                            height: 20,
                            width: 90,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Special',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      item.categoryName?.toUpperCase() ?? 'MENU',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 3, offset: const Offset(0, 1))],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceFormat.format(item.price),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1),
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
