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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BIGGER & SHARPER IMAGE
            Hero(
              tag: 'menu-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 110,
                  height: 110,
                  color: colorScheme.surfaceContainerHighest,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 400, // Sharp on high-DPI screens
                          placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
                          errorWidget: (_, _, _) => Icon(Icons.fastfood, size: 40, color: colorScheme.onSurfaceVariant),
                        )
                      : Icon(Icons.fastfood, size: 40, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  if (item.categoryName != null)
                    Text(
                      item.categoryName!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        priceFormat.format(item.price),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 19, color: colorScheme.primary),
                      ),
                      const Spacer(),
                      // SOLD OUT BADGE (if needed)
                      if (!item.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            'Unavailable',
                            style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold, fontSize: 12),
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
