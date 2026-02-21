import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/_common/widgets/badges/menu_item_badges.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

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
                          child: Icon(Icons.share, color: cs.onSurface),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
