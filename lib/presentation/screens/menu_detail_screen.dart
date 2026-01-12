import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/widgets/menu_item_badges.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    cart.addToCart(
      widget.item,
      quantity: _quantity,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return; // Check if the widget is still mounted

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
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

    return Scaffold(
      backgroundColor: cs.surface,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.pop();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // 1. SCROLLABLE CONTENT
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            // IMAGE SECTION
                            AspectRatio(
                              aspectRatio: 1.2,
                              child: widget.item.imageUrl == null
                                  ? Container(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(Icons.fastfood, size: 60, color: cs.onSurfaceVariant),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: widget.item.imageUrl!,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (_, _, _) => const Icon(Icons.error),
                                    ),
                            ),

                            // DETAILS CONTENT
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + Price
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.item.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        priceFormat.format(widget.item.price),
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 20),
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
                                      widget.item.isAvailable ? _buildTag(context, "Available", Icons.check_circle_outline, color: Colors.green) : _buildTag(context, "Unavailable", Icons.cancel_outlined, color: cs.error),
                                    ],
                                  ),

                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),

                                  Text("Description", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text((widget.item.description?.isNotEmpty ?? false) ? widget.item.description! : "No description available.", style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),

                                  const SizedBox(height: 24),
                                  
                                  // QUANTITY & NOTES
                                  if (widget.item.isAvailable) ...[
                                    Row(
                                      children: [
                                        Text("Quantity", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: cs.outlineVariant),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                onPressed: _decrementQuantity,
                                                icon: const Icon(Icons.remove),
                                                color: _quantity > 1 ? cs.primary : cs.outline,
                                              ),
                                              Text('$_quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                              IconButton(
                                                onPressed: _incrementQuantity,
                                                icon: const Icon(Icons.add),
                                                color: cs.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _notesController,
                                      decoration: InputDecoration(
                                        labelText: 'Special Instructions (Optional)',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        hintText: 'e.g., No sugar, Extra hot',
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 100), // Space for bottom bar
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. FLOATING BACK BUTTON
              Positioned(
                top: 8,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: cs.surface.withValues(alpha: 0.8),
                  radius: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                    padding: EdgeInsets.zero,
                    onPressed: () => context.pop(),
                  ),
                ),
              ),

              // 3. BOTTOM ACTION BAR
              if (widget.item.isAvailable)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
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
                                Text('Total Price', style: theme.textTheme.labelMedium),
                                Text(
                                  priceFormat.format(widget.item.price * _quantity),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _addToCart,
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text("Add to Cart"),
                            ),
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
    );
  }

  Widget _buildTag(BuildContext context, String label, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final finalColor = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: finalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: finalColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: finalColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: finalColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
