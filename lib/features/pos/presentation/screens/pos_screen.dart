import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';
import 'package:urban_cafe/features/pos/presentation/widgets/pos_payment_dialog.dart';
import 'package:urban_cafe/features/pos/presentation/screens/pos_order_history.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<PosProvider>().init();
      final menuProvider = context.read<MenuProvider>();
      // Load ALL items for POS (fetchAdminList loads page 1, then loadMore for rest)
      await menuProvider.fetchAdminList();
      while (menuProvider.hasMore) {
        await menuProvider.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = context.watch<PosProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
        elevation: 0,
        actions: [
          // Sync indicator
          if (posProvider.pendingOrderCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: posProvider.isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary)),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: side-by-side on wide screens, stacked on narrow
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: _buildItemPanel(menuProvider, cs)),
                Container(width: 1, color: AppTheme.outlineVariant),
                SizedBox(width: 340, child: _buildCartPanel(posProvider, cs)),
              ],
            );
          } else {
            return _buildItemPanel(menuProvider, cs);
          }
        },
      ),
      // On narrow screens, show cart as a bottom sheet
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700 || posProvider.cartItemCount == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            onPressed: () => _showCartBottomSheet(context, posProvider),
            icon: Badge(label: Text('${posProvider.cartItemCount}'), child: const Icon(Icons.shopping_cart)),
            label: Text('${posProvider.total.toStringAsFixed(0)} Ks'),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Item Panel (Left Side)
  // ─────────────────────────────────────────────────────────
  Widget _buildItemPanel(MenuProvider menuProvider, ColorScheme cs) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              isDense: true,
            ),
          ),
        ),

        // Category Chips
        SizedBox(height: 44, child: _buildCategoryChips(menuProvider)),
        const SizedBox(height: 4),

        // Items Grid
        Expanded(
          child: menuProvider.loading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : _buildItemGrid(menuProvider),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(MenuProvider menuProvider) {
    // Derive categories from loaded items (items have sub-category info)
    final categoryMap = <String, String>{}; // id -> name
    for (final item in menuProvider.items) {
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
          child: FilterChip(
            label: const Text('All'),
            selected: _selectedCategoryId == null,
            onSelected: (_) => setState(() => _selectedCategoryId = null),
            selectedColor: AppTheme.primaryContainer,
            checkmarkColor: AppTheme.primary,
          ),
        ),
        ...categories.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: _selectedCategoryId == entry.key,
              onSelected: (_) => setState(() => _selectedCategoryId = entry.key),
              selectedColor: AppTheme.primaryContainer,
              checkmarkColor: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemGrid(MenuProvider menuProvider) {
    List<MenuItemEntity> allItems = menuProvider.items;

    // Filter by category
    if (_selectedCategoryId != null) {
      allItems = allItems.where((i) => i.categoryId == _selectedCategoryId).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      allItems = allItems.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    // Only available items
    allItems = allItems.where((i) => i.isAvailable).toList();

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppTheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No items found', style: TextStyle(color: AppTheme.outline, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, childAspectRatio: 0.85, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: allItems.length,
      itemBuilder: (ctx, i) => _PosItemCard(item: allItems[i], onTap: () => _onItemTap(allItems[i])),
    );
  }

  void _onItemTap(MenuItemEntity item) {
    final posProvider = context.read<PosProvider>();
    // If item has variants or addons, show customization dialog
    if (item.variants.isNotEmpty || item.addons.isNotEmpty) {
      _showCustomizationDialog(item);
    } else {
      posProvider.addToCart(item);
      _showAddedSnackBar(item.name);
    }
  }

  void _showAddedSnackBar(String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added'), duration: const Duration(milliseconds: 800), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16)),
    );
  }

  void _showCustomizationDialog(MenuItemEntity item) {
    MenuItemVariant? selectedVariant = item.variants.isNotEmpty ? item.variants.first : null;
    List<MenuItemAddon> selectedAddons = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double price = item.price;
          if (selectedVariant != null) price += selectedVariant!.priceAdjustment;
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
                      children: item.variants
                          .map(
                            (v) => ChoiceChip(
                              label: Text('${v.name} ${v.priceAdjustment > 0 ? "(+${v.priceAdjustment.toStringAsFixed(0)})" : ""}'),
                              selected: selectedVariant?.id == v.id,
                              onSelected: (_) => setDialogState(() => selectedVariant = v),
                              selectedColor: AppTheme.primaryContainer,
                            ),
                          )
                          .toList(),
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
                  Text('Total: ${price.toStringAsFixed(0)} Ks', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
  Widget _buildCartPanel(PosProvider posProvider, ColorScheme cs) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primaryContainer.withValues(alpha: 0.5)),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Current Order',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primary),
                  ),
                ),
                if (posProvider.cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
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
                        Icon(Icons.add_shopping_cart, size: 48, color: AppTheme.outline.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Tap items to add', style: TextStyle(color: AppTheme.outline.withValues(alpha: 0.6), fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posProvider.cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (ctx, i) {
                      final item = posProvider.cartItems[i];
                      return _CartItemTile(item: item, index: i, posProvider: posProvider);
                    },
                  ),
          ),

          // Totals + Charge Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${posProvider.cartItemCount} items', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
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
        ],
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context, PosProvider posProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => _buildCartPanel(posProvider, Theme.of(context).colorScheme),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────
class _PosItemCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onTap;
  const _PosItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppRadius.mdAll,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder with icon
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppTheme.primaryContainer.withValues(alpha: 0.4), borderRadius: AppRadius.smAll),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.coffee, size: 32, color: AppTheme.primary)),
                          ),
                        )
                      : const Center(child: Icon(Icons.coffee, size: 32, color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.price.toStringAsFixed(0)} Ks',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final int index;
  final PosProvider posProvider;
  const _CartItemTile({required this.item, required this.index, required this.posProvider});

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedVariant != null) Text(item.selectedVariant!.name, style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                Text('${item.unitPrice.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
              ],
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceVariant.withValues(alpha: 0.5), borderRadius: AppRadius.smAll),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(icon: Icons.remove, onTap: () => posProvider.updateQuantity(index, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                _QtyButton(icon: Icons.add, onTap: () => posProvider.updateQuantity(index, item.quantity + 1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xsAll,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}
