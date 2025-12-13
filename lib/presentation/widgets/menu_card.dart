// presentation/widgets/menu_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class MenuCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback? onTap;

  const MenuCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        // Reduced vertical padding to fit more items
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Keep aligned to top
          children: [
            // COMPACT IMAGE (80x80)
            Hero(
              tag: 'menu-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Slightly smaller radius
                child: Container(
                  width: 80,
                  height: 80,
                  color: colorScheme.surfaceContainerHighest,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 250, // Reduced cache size for optimization
                          placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
                          errorWidget: (_, _, _) => Icon(Icons.fastfood, size: 24, color: colorScheme.onSurfaceVariant),
                        )
                      : Icon(Icons.fastfood, size: 24, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),

            const SizedBox(width: 12), // Reduced gap
            // CONTENT
            Expanded(
              child: SizedBox(
                height: 80, // Force height to match image for better vertical alignment
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out name/price
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Reduced from 17
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.categoryName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.categoryName!,
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ],
                    ),

                    // PRICE ROW
                    Row(
                      children: [
                        Text(
                          priceFormat.format(item.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16, // Reduced from 19
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        // COMPACT BADGE
                        if (!item.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Unavailable',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10, // Reduced from 12
                              ),
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
    );
  }
}
