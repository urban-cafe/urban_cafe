import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';

class MenuDetailScreen extends StatelessWidget {
  final MenuItemEntity item;
  const MenuDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl != null
                    ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.fastfood, size: 50, color: Colors.grey)),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(NumberFormat.currency(symbol: '', decimalDigits: 0).format(item.price), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(item.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 18),
                const SizedBox(width: 6),
                // Fix: Use categoryName
                Text(item.categoryName ?? 'Other'),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final brand = Theme.of(context).extension<BrandColors>()!;
                    return Icon(item.isAvailable ? Icons.check_circle : Icons.cancel, color: item.isAvailable ? brand.success : brand.danger);
                  },
                ),
                const SizedBox(width: 6),
                Text(item.isAvailable ? 'Available' : 'Unavailable'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
