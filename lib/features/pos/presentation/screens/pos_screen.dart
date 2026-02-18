import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/_common/widgets/inputs/custom_search_bar.dart';
import 'package:urban_cafe/features/cart/domain/entities/cart_item.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/features/pos/data/services/menu_sync_service.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';
import 'package:urban_cafe/features/pos/presentation/screens/pos_order_history.dart';
import 'package:urban_cafe/features/pos/presentation/widgets/pos_payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  List<MenuItemEntity>? _offlineItems;
  bool _loadingOffline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<PosProvider>().init();

      if (kIsWeb) {
        // Web: Load from online (MenuProvider)
        if (!mounted) return;
        setState(() => _loadingOffline = false);
        final menuProvider = context.read<MenuProvider>();
        await menuProvider.fetchAdminList();
        while (menuProvider.hasMore) {
          await menuProvider.loadMore();
        }
      } else {
        // Mobile: Load from local database (offline-first)
        final syncService = context.read<MenuSyncService>();
        final localItems = await syncService.getCachedItems();

        if (localItems.isNotEmpty) {
          if (mounted) {
            setState(() {
              _offlineItems = localItems;
              _loadingOffline = false;
            });
          }
        } else {
          if (!mounted) return;
          setState(() => _loadingOffline = false);
          final menuProvider = context.read<MenuProvider>();
          await menuProvider.fetchAdminList();
          while (menuProvider.hasMore) {
            await menuProvider.loadMore();
          }
        }
      }
    });
  }

  /// Whether the current layout is wide (tablet / landscape).
  bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width > 700;

  @override
  Widget build(BuildContext context) {
    final posProvider = context.watch<PosProvider>();
    final cs = Theme.of(context).colorScheme;
    final isWide = _isWide(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Point of Sale', style: theme.textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
        actions: [
          // Sync indicator
          if (posProvider.pendingOrderCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: posProvider.isSyncing
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                    )
                  : Badge(
                      label: Text('${posProvider.pendingOrderCount}'),
                      child: IconButton(icon: const Icon(Icons.cloud_upload_outlined), onPressed: posProvider.manualSync, tooltip: 'Sync offline orders'),
                    ),
            ),
          // Online/Offline status
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(posProvider.isOnline ? Icons.wifi : Icons.wifi_off, color: posProvider.isOnline ? Colors.greenAccent : Colors.redAccent, size: 20),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PosOrderHistory())),
            tooltip: 'Order History',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ItemPanel(offlineItems: _offlineItems, loadingOffline: _loadingOffline, selectedCategoryId: _selectedCategoryId, searchQuery: _searchQuery, onCategoryChanged: (id) => setState(() => _selectedCategoryId = id), onSearchChanged: (q) => setState(() => _searchQuery = q), onItemTap: _onItemTap),
                ),
                Container(width: 1, color: cs.outlineVariant),
                SizedBox(width: 340, child: _buildCartPanel(posProvider, cs)),
              ],
            )
          : _ItemPanel(offlineItems: _offlineItems, loadingOffline: _loadingOffline, selectedCategoryId: _selectedCategoryId, searchQuery: _searchQuery, onCategoryChanged: (id) => setState(() => _selectedCategoryId = id), onSearchChanged: (q) => setState(() => _searchQuery = q), onItemTap: _onItemTap),
      // On narrow screens, show cart as a FAB
      floatingActionButton: isWide || posProvider.cartItemCount == 0
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton.extended(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                onPressed: () => _showCartBottomSheet(context),
                icon: Badge(label: Text('${posProvider.cartItemCount}'), child: const Icon(Icons.shopping_cart)),
                label: Text('${posProvider.total.toStringAsFixed(0)} Ks'),
              ),
            ),
    );
  }

  void _onItemTap(MenuItemEntity item) {
    final posProvider = context.read<PosProvider>();
    if (item.variants.isNotEmpty || item.addons.isNotEmpty) {
      _showCustomizationDialog(item);
    } else {
      posProvider.addToCart(item);
      _showAddedSnackBar(item.name);
    }
  }

  void _showAddedSnackBar(String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added'), duration: const Duration(milliseconds: 800), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16)));
  }

  void _showCustomizationDialog(MenuItemEntity item) {
    final cs = Theme.of(context).colorScheme;
    MenuItemVariant? selectedVariant = item.variants.isNotEmpty ? item.variants.first : null;
    List<MenuItemAddon> selectedAddons = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double price = item.price;
          if (selectedVariant != null) {
            price += selectedVariant!.priceAdjustment;
          }
          for (final addon in selectedAddons) {
            price += addon.price;
          }

          return AlertDialog(
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.variants.isNotEmpty) ...[
                    const Text('Size / Variant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: item.variants.map((v) => ChoiceChip(label: Text('${v.name} ${v.priceAdjustment > 0 ? "(+${v.priceAdjustment.toStringAsFixed(0)})" : ""}'), selected: selectedVariant?.id == v.id, onSelected: (_) => setDialogState(() => selectedVariant = v), selectedColor: cs.primaryContainer)).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (item.addons.isNotEmpty) ...[
                    const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...item.addons.map(
                      (a) => CheckboxListTile(
                        title: Text(a.name),
                        subtitle: Text('+${a.price.toStringAsFixed(0)} Ks'),
                        value: selectedAddons.any((sa) => sa.id == a.id),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selectedAddons.add(a);
                          } else {
                            selectedAddons.removeWhere((sa) => sa.id == a.id);
                          }
                        }),
                      ),
                    ),
                  ],
                  const Divider(),
                  Text(
                    'Total: ${price.toStringAsFixed(0)} Ks',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.primary),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  context.read<PosProvider>().addToCart(item, selectedVariant: selectedVariant, selectedAddons: selectedAddons);
                  Navigator.pop(ctx);
                  _showAddedSnackBar(item.name);
                },
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Cart Panel (Right Side or Bottom Sheet)
  // ─────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────
  // Cart Panel (Right Side or Bottom Sheet)
  // ─────────────────────────────────────────────────────────
  Widget _buildCartPanel(PosProvider posProvider, ColorScheme cs, {ScrollController? scrollController}) {
    return Container(
      color: cs.surface,
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5)),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Order',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.primary),
                  ),
                ),
                if (posProvider.cartItems.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                    onPressed: posProvider.clearCart,
                    tooltip: 'Clear all',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: posProvider.cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 48, color: cs.outline.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Tap items to add', style: TextStyle(color: cs.outline.withValues(alpha: 0.6), fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posProvider.cartItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (ctx, i) {
                      final item = posProvider.cartItems[i];
                      return _CartItemTile(item: item, index: i, posProvider: posProvider);
                    },
                  ),
          ),

          // Totals + Charge Button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${posProvider.cartItemCount} items', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                      Text('Subtotal: ${posProvider.subtotal.toStringAsFixed(0)} Ks', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: posProvider.cartItems.isEmpty
                          ? null
                          : () => showDialog(
                              context: context,
                              builder: (_) => PosPaymentDialog(total: posProvider.total, posProvider: posProvider),
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 8),
                          Text('Charge ${posProvider.total.toStringAsFixed(0)} Ks', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        // Consumer listens to PosProvider changes so cart updates live
        builder: (ctx, scrollCtrl) => Consumer<PosProvider>(builder: (ctx, posProvider, _) => _buildCartPanel(posProvider, cs, scrollController: scrollCtrl)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Extracted Item Panel — avoids unnecessary parent rebuilds
// ─────────────────────────────────────────────────────────
class _ItemPanel extends StatelessWidget {
  final List<MenuItemEntity>? offlineItems;
  final bool loadingOffline;
  final String? selectedCategoryId;
  final String searchQuery;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MenuItemEntity> onItemTap;

  const _ItemPanel({required this.offlineItems, required this.loadingOffline, required this.selectedCategoryId, required this.searchQuery, required this.onCategoryChanged, required this.onSearchChanged, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final menuProvider = context.watch<MenuProvider>();
    final items = offlineItems ?? menuProvider.items;
    final isLoading = loadingOffline || (offlineItems == null && menuProvider.loading);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: CustomSearchBar(hintText: 'search'.tr(), onChanged: onSearchChanged),
        ),

        // Platform indicator
        if (kIsWeb && offlineItems == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: cs.tertiaryContainer.withValues(alpha: 0.3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud, size: 14, color: cs.tertiary),
                const SizedBox(width: 4),
                Text('Web Mode - Loading from online', style: TextStyle(fontSize: 11, color: cs.tertiary)),
              ],
            ),
          )
        else if (offlineItems != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: cs.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_bolt, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('Offline Mode - Using local data (${offlineItems!.length} items)', style: TextStyle(fontSize: 11, color: cs.primary)),
              ],
            ),
          ),

        // Category Chips
        SizedBox(
          height: 44,
          child: _CategoryChips(items: items, selectedCategoryId: selectedCategoryId, onCategoryChanged: onCategoryChanged),
        ),
        const SizedBox(height: 4),

        // Items Grid
        Expanded(
          child: isLoading ? Center(child: CircularProgressIndicator(color: cs.primary)) : _ItemGrid(items: items, selectedCategoryId: selectedCategoryId, searchQuery: searchQuery, onItemTap: onItemTap),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Category Chips — extracted for rebuild isolation
// ─────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<MenuItemEntity> items;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const _CategoryChips({required this.items, required this.selectedCategoryId, required this.onCategoryChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final categoryMap = <String, String>{};
    for (final item in items) {
      if (item.categoryId != null && item.categoryName != null) {
        categoryMap[item.categoryId!] = item.categoryName!;
      }
    }
    final categories = categoryMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              'All',
              style: TextStyle(color: selectedCategoryId == null ? cs.onPrimary : cs.onSurface, fontWeight: selectedCategoryId == null ? FontWeight.bold : FontWeight.normal),
            ),
            selected: selectedCategoryId == null,
            onSelected: (_) => onCategoryChanged(null),
            showCheckmark: false,
            selectedColor: cs.primary,
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: selectedCategoryId == null ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
        ),
        ...categories.map((entry) {
          final isSelected = selectedCategoryId == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                entry.value,
                style: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged(entry.key),
              showCheckmark: false,
              selectedColor: cs.primary,
              backgroundColor: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isSelected ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Item Grid — extracted + filtered
// ─────────────────────────────────────────────────────────
class _ItemGrid extends StatelessWidget {
  final List<MenuItemEntity> items;
  final String? selectedCategoryId;
  final String searchQuery;
  final ValueChanged<MenuItemEntity> onItemTap;

  const _ItemGrid({required this.items, required this.selectedCategoryId, required this.searchQuery, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var allItems = items.where((i) => i.isAvailable).toList();

    if (selectedCategoryId != null) {
      allItems = allItems.where((i) => i.categoryId == selectedCategoryId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      allItems = allItems.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: cs.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No items found', style: TextStyle(color: cs.outline, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      cacheExtent: 200, // Pre‐render beyond viewport for smoother scroll
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, childAspectRatio: 0.85, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: allItems.length,
      itemBuilder: (ctx, i) => RepaintBoundary(
        child: _PosItemCard(item: allItems[i], onTap: () => onItemTap(allItems[i])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Item Card — uses CachedNetworkImage for offline support
// ─────────────────────────────────────────────────────────
class _PosItemCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onTap;
  const _PosItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: AppRadius.mdAll,
      elevation: 1,
      shadowColor: cs.shadow.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.4), borderRadius: AppRadius.smAll),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Center(
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                            ),
                            errorWidget: (_, _, _) => Center(child: Icon(Icons.coffee, size: 32, color: cs.primary)),
                          ),
                        )
                      : Center(child: Icon(Icons.coffee, size: 32, color: cs.primary)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.price.toStringAsFixed(0)} Ks',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Cart Item Tile — properly typed
// ─────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final PosProvider posProvider;
  const _CartItemTile({required this.item, required this.index, required this.posProvider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedVariant != null) Text(item.selectedVariant!.name, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text('${item.unitPrice.toStringAsFixed(0)} Ks', style: TextStyle(fontSize: 12, color: cs.primary)),
              ],
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: AppRadius.smAll),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(icon: Icons.remove, onTap: () => posProvider.updateQuantity(index, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface),
                  ),
                ),
                _QtyButton(icon: Icons.add, onTap: () => posProvider.updateQuantity(index, item.quantity + 1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.totalPrice.toStringAsFixed(0),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xsAll,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
    );
  }
}
