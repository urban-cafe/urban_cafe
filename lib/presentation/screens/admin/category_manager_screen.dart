import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/core/validators.dart'; // Import Global Validators
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/widgets/add_category_dialog.dart';

class AdminCategoryManagerScreen extends StatefulWidget {
  const AdminCategoryManagerScreen({super.key});

  @override
  State<AdminCategoryManagerScreen> createState() => _AdminCategoryManagerScreenState();
}

class _AdminCategoryManagerScreenState extends State<AdminCategoryManagerScreen> {
  final _repo = MenuRepositoryImpl();
  List<Map<String, dynamic>> _tree = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() => _isLoading = true);
    try {
      final mains = await _repo.getMainCategories();
      List<Map<String, dynamic>> builtTree = [];

      for (var main in mains) {
        final subs = await _repo.getSubCategories(main['id']);
        builtTree.add({'data': main, 'subs': subs});
      }

      if (mounted) setState(() => _tree = builtTree);
    } catch (e) {
      debugPrint("Error loading categories: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerCreate({String? parentId}) async {
    final newId = await showAddCategoryDialog(context, parentId: parentId);

    if (newId != null && mounted) {
      showAppSnackBar(context, "Category Created Successfully");
      _loadTree();
    }
  }

  // UPDATED: Now uses ModalBottomSheet for Rename (Fixes iOS PWA issue)
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
                            _loadTree();
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
          _loadTree();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _triggerCreate(parentId: null), label: const Text("Add Main"), icon: const Icon(Icons.add)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tree.isEmpty
          ? Center(child: Text("No categories yet", style: theme.textTheme.titleMedium))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _tree.length,
              itemBuilder: (context, index) {
                final node = _tree[index];
                final main = node['data'] as Map<String, dynamic>;
                final subs = node['subs'] as List<Map<String, dynamic>>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.only(left: 16, right: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.folder, color: colorScheme.onPrimaryContainer),
                      ),
                      title: Text(main['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), tooltip: "Rename Main Category", onPressed: () => _showRenameDialog(main['id'], main['name'])),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                            tooltip: "Delete Main Category",
                            onPressed: () => _confirmDelete(main['id'], main['name']),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: Border(left: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 4)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 48, right: 16),
                            leading: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
                            title: Text(
                              "Add Sub-Category",
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                            onTap: () => _triggerCreate(parentId: main['id']),
                          ),
                        ),

                        if (subs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text("No sub-categories", style: TextStyle(color: colorScheme.outline)),
                            ),
                          ),

                        ...subs.map(
                          (sub) => Column(
                            children: [
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              ListTile(
                                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                title: Text(sub['name']),
                                leading: const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.grey),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showRenameDialog(sub['id'], sub['name'])),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                                      onPressed: () => _confirmDelete(sub['id'], sub['name']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
