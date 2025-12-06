import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/admin_item_tile.dart';

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
        context.go('/admin/login');
        return;
      }
      context.read<MenuProvider>().fetchAdminList();
    });
    _scrollCtrl.addListener(() {
      final menu = context.read<MenuProvider>();
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        menu.loadMore();
      }
    });
  }

  // FIX: Updated logout handler with Confirmation Dialog
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );

    // Only proceed if user clicked "Log out" (true)
    if (confirm == true && mounted) {
      final auth = context.read<AuthProvider>();
      await auth.signOut();
      if (!mounted) return;
      context.go('/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
          title: const Text('Admin: Menu Items'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: _handleLogout, // Calls the new dialog logic
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final menuProv = context.read<MenuProvider>();
            await context.push('/admin/edit');
            if (!mounted) return;
            await menuProv.fetchAdminList();
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
                child: menu.loading && menu.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        controller: _scrollCtrl,
                        itemCount: menu.items.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = menu.items[index];
                          return AdminItemTile(
                            item: item,
                            onEdit: () async {
                              final menuProv = context.read<MenuProvider>();
                              await context.push('/admin/edit', extra: item);
                              if (!mounted) return;
                              await menuProv.fetchAdminList();
                            },
                            onDelete: () async {
                              final adminProv = context.read<AdminProvider>();
                              final menuProv = context.read<MenuProvider>();
                              final messenger = ScaffoldMessenger.of(context);
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
                                final ok = await adminProv.delete(item.id);
                                if (!context.mounted) return;
                                if (ok) {
                                  messenger.showSnackBar(const SnackBar(content: Text('Deleted')));
                                  await menuProv.fetchAdminList();
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
      ),
    );
  }
}
