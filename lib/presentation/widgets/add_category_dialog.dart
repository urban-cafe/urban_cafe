import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

Future<String?> showAddCategoryDialog(BuildContext context, {String? parentId}) async {
  final isMain = parentId == null;
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // UX IMPROVEMENT: Use ModalBottomSheet instead of Dialog
  // This anchors to the bottom and handles the keyboard naturally without jumping.
  return await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true, // Critical: Allows the sheet to expand with the keyboard
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      // Calculate the bottom padding based on the keyboard height
      final keyboardPadding = MediaQuery.of(ctx).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.only(
          bottom: keyboardPadding + 24, // Keyboard height + spacing
          left: 16,
          right: 16,
          top: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Consumer<AdminProvider>(
            builder: (context, admin, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    isMain ? 'New Main Category' : 'New Sub Category',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: ctrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      enabled: !admin.loading, // Disable input while loading
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => AppValidators.required(value, 'Name'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (admin.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(admin.error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                    ),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: admin.loading ? null : () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: admin.loading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                // We use the provider from the Consumer
                                final id = await admin.addCategory(ctrl.text.trim(), parentId: parentId);

                                if (ctx.mounted && id != null) {
                                  Navigator.pop(ctx, id);
                                }
                              },
                        child: admin.loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
