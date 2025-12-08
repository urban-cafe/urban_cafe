import 'package:flutter/material.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class AdminItemTile extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminItemTile({super.key, required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null, child: item.imageUrl == null ? const Icon(Icons.fastfood) : null),
      title: Text(item.name),
      subtitle: Text(item.categoryName ?? 'Uncategorized'),
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
