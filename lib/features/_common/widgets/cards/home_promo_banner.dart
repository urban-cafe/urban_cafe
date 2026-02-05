import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class HomePromoBanner extends StatelessWidget {
  final List<MenuItemEntity> items;

  const HomePromoBanner({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemWidth = Responsive.isMobile(context) ? MediaQuery.of(context).size.width - 40 : Responsive.width(context, 40); // 40% width on larger screens

    return SizedBox(
      height: 180,
      child: CarouselView(itemExtent: itemWidth, shrinkExtent: 160, itemSnapping: true, children: items.map((item) => _buildPromoCard(context, item)).toList()),
    );
  }

  Widget _buildPromoCard(BuildContext context, MenuItemEntity item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => context.push('/detail', extra: item),
      child: Stack(
        children: [
          // Background Image
          if (item.imageUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.3), colorBlendMode: BlendMode.darken),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary, cs.tertiary]),
                ),
                child: Icon(Icons.local_cafe, size: 120, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'Promo',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Weekend Special:\n${item.name}',
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
