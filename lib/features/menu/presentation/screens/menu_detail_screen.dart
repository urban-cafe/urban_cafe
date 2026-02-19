import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/animations.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/features/_common/widgets/badges/menu_item_badges.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

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
    cart.addToCart(
      widget.item,
      quantity: _quantity.value,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      selectedVariant: _selectedVariant,
      selectedAddons: _selectedAddons.toList(),
    );

    if (!mounted) return;

    showAppSnackBar(context, "Added to Cart Successfully");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final menuProvider = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
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
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: cs.surface,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: cs.onSurface),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                          ),
                          child: AnimatedHeartButton(isFavorite: isFavorite, size: 24, onTap: () => menuProvider.toggleFavorite(widget.item.id)),
                        ),
                      ),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
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
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
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
                        Text(
                          (widget.item.description?.isNotEmpty ?? false) ? widget.item.description! : "No description available.",
                          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.6),
                        ),

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

                        // QUANTITY & NOTES (hidden for guests only)
                        if (widget.item.isAvailable && !auth.isGuest) ...[
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
                                        ScaleTapWidget(
                                          onTap: _decrementQuantity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(Icons.remove, color: qty > 1 ? cs.primary : cs.outline),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '$qty',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        ScaleTapWidget(
                                          onTap: _incrementQuantity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(Icons.add, color: cs.primary),
                                          ),
                                        ),
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
                        if (!auth.isAdmin && !auth.isStaff) const SizedBox(height: 40), // Extra space for guests
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. BOTTOM ACTION BAR (hidden for guests only)
          if (widget.item.isAvailable && !auth.isGuest)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeSlideAnimation(
                slideOffset: const Offset(0, 50),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Price Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('total_price'.tr(), style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<int>(
                                valueListenable: _quantity,
                                builder: (context, qty, child) {
                                  return Text(
                                    priceFormat.format(_currentUnitPrice * qty),
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Add to Cart Button with gradient
                        Expanded(
                          flex: 2,
                          child: ScaleTapWidget(
                            onTap: _addToCart,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: AppRadius.lgAll,
                                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'add_to_cart'.tr(),
                                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        borderRadius: AppRadius.xlAll,
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
