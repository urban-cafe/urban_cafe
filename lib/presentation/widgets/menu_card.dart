// presentation/widgets/menu_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/widgets/menu_item_badges.dart';

class MenuCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback? onTap;

  const MenuCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LARGER IMAGE (100x100)
                Hero(
                  tag: 'menu-${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: colorScheme.surfaceContainerHighest,
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
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
                              item.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17, color: colorScheme.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.categoryName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.categoryName!,
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 6),
                            MenuItemBadges(isMostPopular: item.isMostPopular, isWeekendSpecial: item.isWeekendSpecial),
                          ],
                        ),

                        // PRICE ROW
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceFormat.format(item.price),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary),
                            ),
                            const Spacer(),
                            if (!item.isAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  'Sold Out',
                                  style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                                child: Icon(Icons.add, size: 18, color: colorScheme.onPrimaryContainer),
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
