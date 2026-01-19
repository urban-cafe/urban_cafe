import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/badges/menu_item_badges.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final ValueNotifier<int> _quantity = ValueNotifier(1);
  final TextEditingController _notesController = TextEditingController();

  // Customization State
  MenuItemVariant? _selectedVariant;
  final Set<MenuItemAddon> _selectedAddons = {};

  @override
  void initState() {
    super.initState();
    // Select default variant if available
    if (widget.item.variants.isNotEmpty) {
      final defaultVar = widget.item.variants.where((v) => v.isDefault).firstOrNull;
      _selectedVariant = defaultVar ?? widget.item.variants.first;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    _quantity.value++;
  }

  void _decrementQuantity() {
    if (_quantity.value > 1) {
      _quantity.value--;
    }
  }

  void _toggleAddon(MenuItemAddon addon) {
    setState(() {
      if (_selectedAddons.contains(addon)) {
        _selectedAddons.remove(addon);
      } else {
        _selectedAddons.add(addon);
      }
    });
  }

  void _selectVariant(MenuItemVariant variant) {
    setState(() {
      _selectedVariant = variant;
    });
  }

  double get _currentUnitPrice {
    double price = widget.item.price;
    if (_selectedVariant != null) {
      price += _selectedVariant!.priceAdjustment;
    }
    for (var addon in _selectedAddons) {
      price += addon.price;
    }
    return price;
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    cart.addToCart(widget.item, quantity: _quantity.value, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(), selectedVariant: _selectedVariant, selectedAddons: _selectedAddons.toList());

    if (!mounted) return;

    // Remove current snackbar to prevent stacking/delay
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('added_to_cart'.tr()),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'view_cart'.tr(),
          onPressed: () {
            if (mounted) {
              context.push('/cart');
            }
          },
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final menuProvider = context.watch<MenuProvider>();
    final isFavorite = menuProvider.favoriteIds.contains(widget.item.id);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. IMMERSIVE APP BAR
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: cs.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.8), shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.8), shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : cs.onSurface),
                      onPressed: () => menuProvider.toggleFavorite(widget.item.id),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: widget.item.imageUrl == null
                      ? Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.fastfood, size: 80, color: cs.onSurfaceVariant),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: cs.surfaceContainerHighest),
                          errorWidget: (_, _, _) => const Icon(Icons.error),
                        ),
                ),
              ),

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0), // Overlap effect
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        // Title + Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.name,
                                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              priceFormat.format(widget.item.price),
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Badges
                        MenuItemBadges(isMostPopular: widget.item.isMostPopular, isWeekendSpecial: widget.item.isWeekendSpecial),
                        const SizedBox(height: 16),

                        // Tags
                        Wrap(
                          spacing: 8,
                          children: [
                            if (widget.item.categoryName != null) _buildTag(context, widget.item.categoryName!, Icons.category_outlined),
                            widget.item.isAvailable
                                ? _buildTag(context, "Available", Icons.check_circle_outline, color: cs.secondary) // Use secondary (greenish gold) or success color
                                : _buildTag(context, "Unavailable", Icons.cancel_outlined, color: cs.error),
                          ],
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        Text("Description", style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text((widget.item.description?.isNotEmpty ?? false) ? widget.item.description! : "No description available.", style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.6)),

                        const SizedBox(height: 32),

                        // CUSTOMIZATION
                        if (widget.item.variants.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Size', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.item.variants.map((variant) {
                              final isSelected = _selectedVariant?.id == variant.id;
                              return FilterChip(
                                label: Text('${variant.name} ${variant.priceAdjustment > 0 ? "+${priceFormat.format(variant.priceAdjustment)}" : ""}'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) _selectVariant(variant);
                                },
                                showCheckmark: false,
                                selectedColor: cs.primaryContainer,
                                checkmarkColor: cs.onPrimaryContainer,
                              );
                            }).toList(),
                          ),
                        ],

                        if (widget.item.addons.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Add-ons', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: widget.item.addons.map((addon) {
                              final isSelected = _selectedAddons.contains(addon);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) => _toggleAddon(addon),
                                title: Text(addon.name),
                                secondary: Text(
                                  '+${priceFormat.format(addon.price)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: cs.primary,
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // QUANTITY & NOTES
                        if (widget.item.isAvailable) ...[
                          Row(
                            children: [
                              Text("quantity".tr(), style: theme.textTheme.titleMedium),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _quantity,
                                  builder: (context, qty, child) {
                                    return Row(
                                      children: [
                                        IconButton(onPressed: _decrementQuantity, icon: const Icon(Icons.remove), color: qty > 1 ? cs.primary : cs.outline),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '$qty',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(onPressed: _incrementQuantity, icon: const Icon(Icons.add), color: cs.primary),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'special_instructions'.tr(),
                              hintText: 'e.g., No sugar, Extra hot',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 120), // Space for bottom bar
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. BOTTOM ACTION BAR
          if (widget.item.isAvailable)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('total_price'.tr(), style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ValueListenableBuilder<int>(
                              valueListenable: _quantity,
                              builder: (context, qty, child) {
                                // Force rebuild when customization changes (using setState in parent)
                                // Actually ValueListenableBuilder only rebuilds on value change.
                                // We need to wrap this in a builder that listens to state changes or just use setState.
                                // Since we call setState in _selectVariant/_toggleAddon, the whole build runs.
                                return Text(
                                  priceFormat.format(_currentUnitPrice * qty),
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text("add_to_cart".tr()),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final finalColor = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: finalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: finalColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: finalColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: finalColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
