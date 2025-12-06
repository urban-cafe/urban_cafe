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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image on the Left
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant),
                            ),
                          )
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant),
                          ),
                  ),
                ),
                // "Sold Out" Overlay on Image (if needed)
                if (!item.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text(
                        'SOLD OUT',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // 2. Details on the Right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 4), // Visual alignment with image top
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.categoryName != null)
                    Text(
                      item.categoryName!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 8),
                  Text(priceFormat.format(item.price), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
            ),

            // Optional: Add Icon button or arrow here if you want
            // const Icon(Icons.add_circle, color: Colors.green, size: 28),
          ],
        ),
      ),
    );
  }
}
