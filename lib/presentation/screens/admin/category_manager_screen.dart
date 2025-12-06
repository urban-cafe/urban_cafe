import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRenameDialog(String id, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().renameCategory(id, ctrl.text);
              if (success) _loadTree(); // Refresh tree
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tree.length,
              itemBuilder: (context, index) {
                final node = _tree[index];
                final main = node['data'] as Map<String, dynamic>;
                final subs = node['subs'] as List<Map<String, dynamic>>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(main['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    leading: const Icon(Icons.folder),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showRenameDialog(main['id'], main['name'])),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                    children: subs.isEmpty
                        ? [
                            const ListTile(
                              title: Text(
                                'No sub-categories',
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ),
                          ]
                        : subs
                              .map(
                                (sub) => ListTile(
                                  title: Text(sub['name']),
                                  leading: const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.grey),
                                  trailing: IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showRenameDialog(sub['id'], sub['name'])),
                                ),
                              )
                              .toList(),
                  ),
                );
              },
            ),
    );
  }
}
