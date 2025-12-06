import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class MenuCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback? onTap;
  const MenuCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
                        fadeInDuration: const Duration(milliseconds: 200),
                        memCacheWidth: 600,
                        memCacheHeight: 450,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.fastfood, color: Colors.grey)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        // Fix: Use categoryName
                        child: Text(item.categoryName ?? 'Other', style: Theme.of(context).textTheme.labelSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(priceFormat.format(item.price), style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          final brand = Theme.of(context).extension<BrandColors>()!;
                          return Icon(item.isAvailable ? Icons.check_circle : Icons.cancel, color: item.isAvailable ? brand.success : brand.danger, size: 18);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
