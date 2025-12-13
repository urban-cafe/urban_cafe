import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
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
  late MenuProvider menuProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final auth = context.read<AuthProvider>();
      if (!auth.isConfigured || !auth.isLoggedIn) {
        context.go('/admin/login');
        return;
      }

      menuProvider.fetchAdminList();
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        menuProvider.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    menuProvider.resetSearch("");
    super.dispose();
  }

  // --- Dummy Data for Skeleton ---
  MenuItemEntity get _dummyItem => MenuItemEntity(id: 'dummy', name: 'Loading Item Name ...', description: null, price: 0, categoryId: null, categoryName: 'Category', imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

  List<MenuItemEntity> get _loadingItems {
    return List.generate(8, (index) => _dummyItem);
  }
  // -------------------------------

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // M3: Title uses Headline Small automatically
        title: const Text('Log out'),
        // M3: Content uses Body Medium automatically
        content: const Text('Are you sure you want to log out?'),
        actions: [
          // Secondary Action: Standard TextButton
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

          // Primary Action: TextButton with Error Color (Standard M3 for destructive dialogs)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error, // Red text for "Log out"
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
          title: Text(
            'Admin Dashboard',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
          ),
          actions: [
            // 1. Updated App Bar Actions
            IconButton(
              icon: const Icon(Icons.category_outlined), // M3 prefers outlined icons
              tooltip: 'Manage Categories',
              onPressed: () => context.push('/admin/categories'),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined), // M3 prefers outlined icons
              tooltip: 'Log out',
              onPressed: _handleLogout,
            ),
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
            // DASHBOARD HEADER (Search)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16), isDense: true),
                        onChanged: (v) => menuProvider.setSearch(v),
                        onSubmitted: (v) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // STATS ROW (Selector)
            // OPTIMIZATION: Only rebuilds this specific Text widget when item count changes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Selector<MenuProvider, int>(
                    selector: (_, provider) => provider.items.length,
                    builder: (context, count, child) {
                      return Text(
                        "Total Items: $count",
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // LIST WITH SKELETONIZER (Consumer)
            // OPTIMIZATION: Only this Expanded area rebuilds when data loads/changes
            Expanded(
              child: Consumer<MenuProvider>(
                builder: (context, menu, child) {
                  final isLoadingInitial = menu.loading && menu.items.isEmpty;
                  final displayItems = isLoadingInitial ? _loadingItems : menu.items;

                  return Skeletonizer(
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
                                        if (!context.mounted) return;
                                        await menuProv.fetchAdminList();
                                      },
                                onDelete: isLoadingInitial
                                    ? () {}
                                    : () async {
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
