import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/core/theme.dart';
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
      // Check actual tree, not displayTree (which returns skeleton data when loading)
      if (provider.tree.isEmpty) {
        provider.loadTree();
      }
    });
  }

  Future<void> _triggerCreate({String? parentId}) async {
    final newId = await showAddCategoryDialog(context, parentId: parentId);

    if (newId != null && mounted) {
      showAppSnackBar(context, 'category_created_successfully'.tr());
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
                  'rename_category'.tr(),
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
                    decoration: InputDecoration(labelText: 'category_name'.tr(), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    validator: (value) => AppValidators.required(value, 'Name'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        Navigator.pop(ctx);
                        final success = await context.read<AdminProvider>().renameCategory(id, ctrl.text.trim());

                        if (mounted) {
                          if (success) {
                            showAppSnackBar(context, 'category_renamed_successfully'.tr());
                            if (mounted) context.read<CategoryManagerProvider>().loadTree();
                          } else {
                            showAppSnackBar(context, 'failed_to_rename'.tr(), isError: true);
                          }
                        }
                      },
                      child: Text('save'.tr()),
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
        title: Text('delete_category'.tr()),
        content: Text('delete_category_confirm'.tr(args: [name])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AdminProvider>().deleteCategory(id);
      if (mounted) {
        if (success) {
          showAppSnackBar(context, 'category_deleted_successfully'.tr());
          if (mounted) context.read<CategoryManagerProvider>().loadTree();
        } else {
          showAppSnackBar(context, 'failed_to_delete_category'.tr(), isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Responsive padding
    final sizeClass = Responsive.windowSizeClass(context);
    final horizontalPadding = switch (sizeClass) {
      WindowSizeClass.compact => 16.0,
      WindowSizeClass.medium => 24.0,
      WindowSizeClass.expanded => 40.0,
    };

    return PopScope(
      canPop: false, // 1. PREVENT the default system pop
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Safety check (should be false now)
        // 2. Perform your custom actions
        FocusScope.of(context).unfocus(); // Close keyboard first
        context.pop(); // Navigate to Main Menu
      },
      child: Scaffold(
        appBar: AppBar(title: Text('manage_categories'.tr(), style: theme.textTheme.titleMedium)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_admin_add_category',
          onPressed: () => _triggerCreate(parentId: null),
          label: Text('add_main'.tr()),
          icon: const Icon(Icons.add),
        ),

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
                            child: Center(child: Text('no_categories_yet'.tr(), style: theme.textTheme.titleMedium)),
                          ),
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: 80),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final node = displayList[index];
                              final main = node['data'] as Map<String, dynamic>;
                              final subs = node['subs'] as List<Map<String, dynamic>>;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    collapsedShape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: AppRadius.mdAll),
                                      child: Icon(Icons.folder_outlined, color: colorScheme.onPrimaryContainer),
                                    ),
                                    title: Text(main['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    subtitle: Text(
                                      'sub_categories_count'.tr(args: [subs.length.toString()]),
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                    ),
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
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                                  tooltip: 'rename'.tr(),
                                                  onPressed: isLoading ? null : () => _showRenameDialog(sub['id'], sub['name']),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                                  tooltip: 'delete'.tr(),
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
                                                'add_sub_category'.tr(),
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
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
