import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

/// Shows a dialog to create a new category.
/// Returns the [id] of the newly created category, or null if cancelled.
Future<String?> showAddCategoryDialog(BuildContext context, {String? parentId}) async {
  final isMain = parentId == null;
  final ctrl = TextEditingController();

  return await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isMain ? 'New Main Category' : 'New Sub Category'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (ctrl.text.trim().isEmpty) return;

            // Use the AdminProvider to create the category
            final id = await ctx.read<AdminProvider>().addCategory(ctrl.text.trim(), parentId: parentId);

            if (ctx.mounted) {
              // Return the new ID back to the caller
              Navigator.pop(ctx, id);
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
