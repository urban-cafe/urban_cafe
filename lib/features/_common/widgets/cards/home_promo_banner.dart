import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/core/theme.dart';
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

    final itemWidth = Responsive.isCompact(context) ? MediaQuery.sizeOf(context).width - 48 : Responsive.width(context, 45);

    return Column(
      children: [
        // Carousel
        SizedBox(
          height: 200,
          child: CarouselView(
            controller: _controller,
            itemExtent: itemWidth,
            shrinkExtent: itemWidth * 0.85,
            itemSnapping: true,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            onTap: (index) => context.push('/detail', extra: widget.items[index]),
            children: widget.items.asMap().entries.map((entry) {
              return _PromoCard(item: entry.value, isActive: entry.key == _currentIndex);
            }).toList(),
          ),
        ),

        // Page Indicators
        if (widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: index == _currentIndex ? 24 : 8,
                  decoration: BoxDecoration(
                    color: index == _currentIndex ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
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
        borderRadius: AppRadius.lgAll,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (item.imageUrl != null)
              CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary, cs.tertiary]),
                ),
                child: Icon(Icons.local_cafe, size: 120, color: Colors.white.withValues(alpha: 0.1)),
              ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.75)],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.error, cs.error.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: cs.error.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Special',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${priceFormat.format(item.price)} Ks',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          item.categoryName ?? 'Menu',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
