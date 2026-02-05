import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/features/_common/widgets/dialogs/add_category_dialog.dart';
import 'package:urban_cafe/features/admin/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/category_manager_provider.dart';

class AdminCategoryManagerScreen extends StatefulWidget {
  const AdminCategoryManagerScreen({super.key});

  @override
  State<AdminCategoryManagerScreen> createState() => _AdminCategoryManagerScreenState();
}

class _AdminCategoryManagerScreenState extends State<AdminCategoryManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data on init, but logic lives in Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoryManagerProvider>();
      if (provider.displayTree.isEmpty) {
        provider.loadTree();
      }
    });
  }

  Future<void> _triggerCreate({String? parentId}) async {
    final newId = await showAddCategoryDialog(context, parentId: parentId);

    if (newId != null && mounted) {
      showAppSnackBar(context, "Category Created Successfully");
      if (mounted) context.read<CategoryManagerProvider>().loadTree();
    }
  }

  Future<void> _showRenameDialog(String id, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final keyboardPadding = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardPadding + 24, left: 16, right: 16, top: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rename Category',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    validator: (value) => AppValidators.required(value, 'Name'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        Navigator.pop(ctx);
                        final success = await context.read<AdminProvider>().renameCategory(id, ctrl.text.trim());

                        if (mounted) {
                          if (success) {
                            showAppSnackBar(context, "Category Renamed Successfully");
                            if (mounted) context.read<CategoryManagerProvider>().loadTree();
                          } else {
                            showAppSnackBar(context, "Failed to Rename", isError: true);
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$name"?\n\nItems in this category will be unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AdminProvider>().deleteCategory(id);
      if (mounted) {
        if (success) {
          showAppSnackBar(context, "Category Deleted Successfully");
          if (mounted) context.read<CategoryManagerProvider>().loadTree();
        } else {
          showAppSnackBar(context, "Failed to delete category", isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, // 1. PREVENT the default system pop
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Safety check (should be false now)
        // 2. Perform your custom actions
        FocusScope.of(context).unfocus(); // Close keyboard first
        context.pop(); // Navigate to Main Menu
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Manage Categories',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.colorScheme.onSurface),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _triggerCreate(parentId: null), label: const Text("Add Main"), icon: const Icon(Icons.add)),

        // Consumer to listen to Provider changes
        body: Consumer<CategoryManagerProvider>(
          builder: (context, provider, child) {
            final displayList = provider.displayTree;
            final isLoading = provider.isLoading;

            return RefreshIndicator(
              onRefresh: () async => provider.loadTree(),
              child: Skeletonizer(
                enabled: isLoading,
                effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                child: displayList.isEmpty && !isLoading
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(child: Text("No categories yet", style: theme.textTheme.titleMedium)),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final node = displayList[index];
                          final main = node['data'] as Map<String, dynamic>;
                          final subs = node['subs'] as List<Map<String, dynamic>>;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.folder_outlined, color: colorScheme.onPrimaryContainer),
                                ),
                                title: Text(main['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text('${subs.length} sub-categories', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                // Custom Trailing for Main Category
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: isLoading ? null : () => _showRenameDialog(main['id'], main['name'])),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                      onPressed: isLoading ? null : () => _confirmDelete(main['id'], main['name']),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.expand_more),
                                  ],
                                ),
                                children: [
                                  const Divider(height: 1),
                                  // Sub-categories List
                                  ...subs.map(
                                    (sub) => Container(
                                      color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                                        title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                        leading: const Icon(Icons.subdirectory_arrow_right, size: 20, color: Colors.grey),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Rename', onPressed: isLoading ? null : () => _showRenameDialog(sub['id'], sub['name'])),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                              tooltip: 'Delete',
                                              onPressed: isLoading ? null : () => _confirmDelete(sub['id'], sub['name']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Add Sub-Category Button
                                  InkWell(
                                    onTap: isLoading ? null : () => _triggerCreate(parentId: main['id']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 56), // Align with sub-cat text
                                          Icon(Icons.add_circle_outline, size: 20, color: colorScheme.primary),
                                          const SizedBox(width: 12),
                                          Text(
                                            "Add Sub-Category",
                                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
