import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class GridMenuCard extends StatelessWidget {
  final MenuItemEntity item;

  const GridMenuCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/detail', extra: item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8), // Small padding for the whole card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                Expanded(
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'menu-grid-${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            color: cs.surfaceContainerHighest,
                            child: item.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 400, // Optimization
                                    placeholder: (_, _) => Container(color: cs.surfaceContainerHighest),
                                    errorWidget: (_, _, _) => Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40),
                                  )
                                : Icon(Icons.local_cafe, color: cs.outlineVariant, size: 40),
                          ),
                        ),
                      ),
                      // Rating Badge (Mock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8), backgroundBlendMode: BlendMode.darken),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                              SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // TEXT
                Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(item.categoryName ?? 'Coffee', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),

                const SizedBox(height: 12),

                // PRICE & ADD BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      priceFormat.format(item.price),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
