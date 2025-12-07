import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/screens/admin/category_manager_screen.dart';
import 'package:urban_cafe/presentation/widgets/admin_item_tile.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  // REMOVED: _selectedFilterName

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isConfigured || !auth.isLoggedIn) {
        context.go('/admin/login');
        return;
      }

      final menu = context.read<MenuProvider>();
      menu.fetchAdminList();
      // REMOVED: menu.loadCategoriesForAdminFilter() since filtering is gone
    });

    _scrollCtrl.addListener(() {
      final menu = context.read<MenuProvider>();
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        menu.loadMore();
      }
    });
  }

  // REMOVED: _showFilterSheet() method

  // --- Dummy Data for Skeleton ---
  MenuItemEntity get _dummyItem => MenuItemEntity(id: 'dummy', name: 'Loading Item Name ...', description: null, price: 0, categoryId: null, categoryName: 'Category', imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

  List<MenuItemEntity> get _loadingItems {
    return List.generate(8, (index) => _dummyItem);
  }
  // -------------------------------

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isLoadingInitial = menu.loading && menu.items.isEmpty;
    final displayItems = isLoadingInitial ? _loadingItems : menu.items;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.category),
              tooltip: 'Manage Categories',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryManagerScreen())),
            ),
            IconButton(icon: const Icon(Icons.logout), tooltip: 'Log out', onPressed: _handleLogout),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final menuProv = context.read<MenuProvider>();
            await context.push('/admin/edit');
            if (!mounted) return;
            await menuProv.fetchAdminList();
          },
          label: const Text("New Item"),
          icon: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            // DASHBOARD HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search items...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      onChanged: (v) => menu.setSearch(v),
                    ),
                  ),
                  // REMOVED: Filter Button and SizedBox here
                ],
              ),
            ),

            // STATS ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "Total Items: ${menu.items.length}",
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  // REMOVED: Selected Filter Name indicator
                ],
              ),
            ),

            const Divider(height: 1),

            // LIST WITH SKELETONIZER
            Expanded(
              child: Skeletonizer(
                enabled: isLoadingInitial,
                effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                child: menu.items.isEmpty && !isLoadingInitial
                    ? const Center(child: Text('No items found'))
                    : ListView.separated(
                        controller: _scrollCtrl,
                        itemCount: displayItems.length + (menu.loadingMore ? 1 : 0),
                        separatorBuilder: (context, _) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          if (index == displayItems.length) {
                            return Skeletonizer(
                              enabled: true,
                              child: AdminItemTile(item: _dummyItem, onEdit: () {}, onDelete: () {}),
                            );
                          }

                          final item = displayItems[index];
                          return AdminItemTile(
                            item: item,
                            onEdit: isLoadingInitial
                                ? () {}
                                : () async {
                                    final menuProv = context.read<MenuProvider>();
                                    await context.push('/admin/edit', extra: item);
                                    if (!mounted) return;
                                    await menuProv.fetchAdminList();
                                  },
                            onDelete: isLoadingInitial
                                ? () {}
                                : () async {
                                    final adminProv = context.read<AdminProvider>();
                                    final menuProv = context.read<MenuProvider>();
                                    // Use Global Utils for Snackbar? Or keep local for now.
                                    // Assuming you want to keep existing logic unless specified.
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
            ),
          ],
        ),
      ),
    );
  }
}
