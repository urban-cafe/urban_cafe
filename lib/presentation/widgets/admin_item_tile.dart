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
      // Keep original circular avatar
      leading: CircleAvatar(backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null, child: item.imageUrl == null ? const Icon(Icons.fastfood) : null),

      // 1. BETTER TYPOGRAPHY: Bolder title for better readability
      title: Text(
        item.name,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      ),

      // 2. STATUS INDICATOR: Added next to category
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Name
          Text(item.categoryName ?? 'Uncategorized', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),

          // Show "Sold Out" tag if item is unavailable
          if (!item.isAvailable) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(4)),
              child: Text(
                "Unavailable",
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
