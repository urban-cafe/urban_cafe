import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class MenuDetailScreen extends StatelessWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. IMMERSIVE IMAGE HEADER
          SliverAppBar(
            expandedHeight: 400, // Makes the image nice and tall (Full Size feel)
            pinned: true, // App bar sticks to top when scrolling
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface, // Back button color logic
            // Only show title in App Bar when collapsed
            title: Text(
              item.name,
              style: const TextStyle(color: Colors.transparent), // Hidden initially
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // The Image
                  item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.fastfood, size: 60, color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.fastfood, size: 60, color: colorScheme.onSurfaceVariant),
                        ),

                  // Gradient Overlay (Shadow) for better text contrast if we had text on image
                  // Also adds a nice fade at the bottom
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.transparent], stops: [0.0, 0.3, 1.0]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTENT BODY
          SliverToBoxAdapter(
            child: Container(
              // Visual trick: Overlap the image slightly with rounded corners
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar (Visual cue for sheet)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),

                    // Title and Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          priceFormat.format(item.price),
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tags Row (Category & Availability)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (item.categoryName != null) _buildTag(context, item.categoryName!, Icons.category_outlined),

                        if (item.isAvailable) _buildTag(context, "Available", Icons.check_circle_outline, color: Colors.green) else _buildTag(context, "Sold Out", Icons.cancel_outlined, color: colorScheme.error),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description Section
                    Text("Description", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      item.description != null && item.description!.isNotEmpty ? item.description! : "No description available.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5, // Better readability
                      ),
                    ),

                    // Extra space at bottom for scrolling
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Category/Status tags
  Widget _buildTag(BuildContext context, String label, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final finalColor = color ?? colorScheme.primary;

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
            style: theme.textTheme.labelLarge?.copyWith(color: finalColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
