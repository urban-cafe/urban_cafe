import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/utils.dart'; // IMPORT THE GLOBAL UTILS
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

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

  // NOTE: _showMsg function is removed. We use showAppSnackBar directly.

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

  Future<void> _showEditDialog({required String title, String? currentName, String? id, String? parentId, required bool isCreating}) async {
    final ctrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);

              final adminProv = context.read<AdminProvider>();
              bool success = false;
              String actionType = "";

              if (isCreating) {
                actionType = "Created";
                final newId = await adminProv.addCategory(ctrl.text.trim(), parentId: parentId);
                success = newId != null;
              } else {
                actionType = "Updated";
                if (id != null) {
                  success = await adminProv.renameCategory(id, ctrl.text.trim());
                }
              }

              if (mounted) {
                if (success) {
                  showAppSnackBar(context, "Category $actionType Successfully"); // GLOBAL USAGE
                  _loadTree();
                } else {
                  showAppSnackBar(context, "Failed to $actionType Category", isError: true); // GLOBAL USAGE
                }
              }
            },
            child: Text(isCreating ? 'Create' : 'Save'),
          ),
        ],
      ),
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
          showAppSnackBar(context, "Category Deleted Successfully"); // GLOBAL USAGE
          _loadTree();
        } else {
          showAppSnackBar(context, "Failed to delete category", isError: true); // GLOBAL USAGE
        }
      }
    }
  }

  // ... (Build method remains exactly the same as previous step) ...
  @override
  Widget build(BuildContext context) {
    // ... Copy the Build method from the previous response ...
    // Just ensure you import the new utils file at the top.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(title: 'New Main Category', isCreating: true),
        label: const Text("Add Main"),
        icon: const Icon(Icons.add),
      ),
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
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: "Rename Main Category",
                            onPressed: () => _showEditDialog(title: 'Rename Category', currentName: main['name'], id: main['id'], isCreating: false),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
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
                            onTap: () => _showEditDialog(title: 'New Sub Category for ${main['name']}', parentId: main['id'], isCreating: true),
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
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showEditDialog(title: 'Rename Sub Category', currentName: sub['name'], id: sub['id'], isCreating: false),
                                    ),
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
