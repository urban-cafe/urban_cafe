import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/menu_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MenuProvider>();

    // We need to filter items from the main list that match favorite IDs
    // Note: Ideally, we should have a dedicated API to fetch favorited items if they are not in the current list
    // But for now, let's assume we can fetch them or they are loaded.
    // If we only have IDs, we might need to fetch the items details if not cached.
    // However, MenuProvider mainly stores `items` for the current category.
    // So we might need a way to get items by IDs.
    // Let's implement a simple filter for now, assuming items might be loaded or we need to fetch them.
    // Actually, `getMenuItemsUseCase` supports `categoryIds`, maybe we should add `ids` filter?
    // For this MVP, let's just show favorites if they are in the loaded `items` OR we should trigger a fetch by IDs.
    // Let's add a method in MenuProvider to fetch favorites details.

    // Better approach: Let's fetch favorite items specifically.

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Builder(
        builder: (context) {
          if (provider.loading && provider.favoriteIds.isEmpty) {
            return Skeletonizer(
              enabled: true,
              child: ListView.builder(
                itemCount: 5,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) => const Card(child: SizedBox(height: 100)),
              ),
            );
          }

          if (provider.favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Display items
          return ListView.builder(
            itemCount: provider.favoriteItems.length,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemBuilder: (context, index) {
              final item = provider.favoriteItems[index];
              return MenuCard(item: item, onTap: () => _openDetail(context, item));
            },
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, dynamic item) {
    context.push('/detail', extra: item);
  }
}
