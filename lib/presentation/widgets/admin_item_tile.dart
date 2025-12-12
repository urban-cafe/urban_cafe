// presentation/widgets/admin_item_tile.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class AdminItemTile extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminItemTile({super.key, required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // PERFECT SQUARE IMAGE (80×80, sharp & clear)
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1.0, // Forces square shape
          child: Container(
            width: 80,
            height: 80,
            color: colorScheme.surfaceContainerHighest,
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 300, // Sharp on high-DPI screens
                    placeholder: (_, _) => const SizedBox(),
                    errorWidget: (_, _, _) => const Icon(Icons.fastfood, size: 32),
                  )
                : const Icon(Icons.fastfood, size: 32, color: Colors.white70),
          ),
        ),
      ),

      title: Text(
        item.name,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.categoryName != null)
            Text(
              item.categoryName!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.price.toStringAsFixed(0),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 17),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: item.isAvailable ? colorScheme.primaryContainer : colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.isAvailable ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ],
      ),

      // Only Delete button
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 26),
        onPressed: onDelete,
        tooltip: 'Delete',
      ),

      // Tap anywhere to edit
      onTap: onEdit,
    );
  }
}
