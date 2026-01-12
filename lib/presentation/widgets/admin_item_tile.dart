// presentation/widgets/admin_item_tile.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/widgets/menu_item_badges.dart';

class AdminItemTile extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminItemTile({super.key, required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow, // Subtle contrast against background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE THUMBNAIL
              if (item.id == 'dummy')
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 88,
                    height: 88,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.fastfood, size: 32, color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                Hero(
                  tag: 'admin_img_${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 88,
                      height: 88,
                      color: colorScheme.surfaceContainerHighest,
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              fadeInDuration: Duration.zero, // Prevent flickering when scrolling back up
                              placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
                              errorWidget: (_, _, _) => Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant),
                            )
                          : Icon(Icons.fastfood, size: 32, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),

              const SizedBox(width: 16),

              // 2. CONTENT COLUMN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
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
                            ],
                          ),
                        ),
                        // Delete Button (Small and unobtrusive)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap, backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2)),
                            onPressed: onDelete,
                            tooltip: 'Delete Item',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Badges (Using the shared widget)
                    MenuItemBadges(isMostPopular: item.isMostPopular, isWeekendSpecial: item.isWeekendSpecial),

                    const SizedBox(height: 8),

                    // Price and Availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          priceFormat.format(item.price),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary, fontSize: 16),
                        ),
                        _AvailabilityBadge(isAvailable: item.isAvailable),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final color = isAvailable ? Colors.green : cs.error;
    final bgColor = isAvailable ? Colors.green.shade50 : cs.errorContainer;
    final label = isAvailable ? 'Available' : 'Unavailable';
    final icon = isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
