// presentation/screens/admin/list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/tiles/admin_item_tile.dart';

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

      if (menuProvider.items.isEmpty) {
        menuProvider.fetchAdminList();
      }
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
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
          title: Text(
            'Admin Dashboard',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colorScheme.onSurface),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final menuProv = context.read<MenuProvider>();
            final bool? didCreate = await context.push<bool>('/admin/edit');
            if (!mounted) return;
            if (didCreate == true) {
              await menuProv.fetchAdminList();
            }
          },
          label: const Text("New Item"),
          icon: const Icon(Icons.add),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await menuProvider.fetchAdminList();
          },
          child: Column(
            children: [
              // 1. DASHBOARD HEADER (Search + Stats)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                            hintText: 'Search menu items...',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            isDense: true,
                          ),
                          onChanged: (v) => menuProvider.setSearch(v),
                          onSubmitted: (v) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Count Chip
                    Selector<MenuProvider, int>(
                      selector: (_, provider) => provider.items.length,
                      builder: (context, count, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$count",
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer, fontSize: 16, height: 1.1),
                              ),
                              Text("Items", style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8))),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. LIST
              Expanded(
                child: Consumer<MenuProvider>(
                  builder: (context, menu, child) {
                    final isLoadingInitial = menu.loading && menu.items.isEmpty;
                    final displayItems = isLoadingInitial ? _loadingItems : menu.items;

                    return Skeletonizer(
                      enabled: isLoadingInitial,
                      effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                      child: menu.items.isEmpty && !isLoadingInitial
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64, color: colorScheme.outlineVariant),
                                  const SizedBox(height: 16),
                                  Text('No items found', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              cacheExtent: 2000, // Keep more items in memory to prevent smooth scrolling issues and image reloading
                              padding: const EdgeInsets.only(bottom: 80, top: 4), // Space for FAB
                              itemCount: displayItems.length + (menu.loadingMore ? 1 : 0),
                              physics: const AlwaysScrollableScrollPhysics(), // Allow pull-to-refresh even when empty
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
                                          // Wait for result from Edit Screen
                                          final bool? didUpdate = await context.push<bool>('/admin/edit', extra: item);

                                          // Only refresh if data was actually changed
                                          if (!context.mounted) return;
                                          if (didUpdate == true) {
                                            await menuProv.fetchAdminList();
                                          }
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
                                              content: Text('Are you sure you want to delete "${item.name}"?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final ok = await adminProv.delete(item.id);
                                            if (!context.mounted) return;
                                            if (ok) {
                                              messenger.showSnackBar(const SnackBar(content: Text('Deleted successfully')));
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
      ),
    );
  }
}
