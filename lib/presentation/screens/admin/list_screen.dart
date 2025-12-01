import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/widgets/admin_item_tile.dart';
import 'package:urban_cafe/presentation/screens/admin/edit_screen.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isConfigured || !auth.isLoggedIn) {
        Navigator.pushNamed(context, '/admin/login');
        return;
      }
      context.read<MenuProvider>().fetch();
    });
    _scrollCtrl.addListener(() {
      final menu = context.read<MenuProvider>();
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        menu.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Menu Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              await auth.signOut();
              navigator.pushReplacementNamed('/admin/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditScreen()));
          await context.read<MenuProvider>().fetch();
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search menu'),
                    onSubmitted: (v) => menu.setSearch(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: menu.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: menu.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = menu.items[index];
                        return AdminItemTile(
                          item: item,
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminEditScreen(id: item.id, item: item),
                              ),
                            );
                            await context.read<MenuProvider>().fetch();
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete item?'),
                                content: const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final ok = await context.read<AdminProvider>().delete(item.id);
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                                await context.read<MenuProvider>().fetch();
                              }
                            }
                          },
                        );
                      },
                    ),
            ),
            if (menu.loadingMore) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
