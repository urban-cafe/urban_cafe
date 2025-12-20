import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/widgets/menu_item_badges.dart';

class MenuDetailScreen extends StatelessWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // IMAGE SECTION
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: item.imageUrl == null
                            ? Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.fastfood, size: 60, color: cs.onSurfaceVariant),
                              )
                            : CachedNetworkImage(
                                imageUrl: item.imageUrl!,
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
                                    item.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  priceFormat.format(item.price),
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 20),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Badges
                            MenuItemBadges(isMostPopular: item.isMostPopular, isWeekendSpecial: item.isWeekendSpecial),
                            const SizedBox(height: 16),

                            // Tags
                            Wrap(
                              spacing: 8,
                              children: [
                                if (item.categoryName != null) _buildTag(context, item.categoryName!, Icons.category_outlined),
                                item.isAvailable ? _buildTag(context, "Available", Icons.check_circle_outline, color: Colors.green) : _buildTag(context, "Unavailable", Icons.cancel_outlined, color: cs.error),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            Text("Description", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text((item.description?.isNotEmpty ?? false) ? item.description! : "No description available.", style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. FLOATING BACK BUTTON
              // Since we are inside SafeArea, we don't need padding.top anymore.
              // Just a small margin from the top-left of the safe area.
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
