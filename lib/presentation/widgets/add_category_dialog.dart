import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/validators.dart'; // Import Global Validators
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

Future<String?> showAddCategoryDialog(BuildContext context, {String? parentId}) async {
  final isMain = parentId == null;
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>(); // Key to identify the form

  return await showDialog<String?>(
    useSafeArea: true,
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isMain ? 'New Main Category' : 'New Sub Category'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            scrollPadding: const EdgeInsets.only(bottom: 200),
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            // USE GLOBAL VALIDATOR
            validator: (value) => AppValidators.required(value, 'Name'),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            // CHECK VALIDATION
            if (!formKey.currentState!.validate()) return;

            final id = await ctx.read<AdminProvider>().addCategory(ctrl.text.trim(), parentId: parentId);

            if (ctx.mounted) {
              Navigator.pop(ctx, id);
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
