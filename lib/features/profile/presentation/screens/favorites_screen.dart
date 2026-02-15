import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/features/_common/widgets/cards/menu_card.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

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
      final provider = context.read<MenuProvider>();
      if (provider.favoriteIds.isEmpty) {
        provider.loadFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text('favorites'.tr()), centerTitle: true, backgroundColor: theme.colorScheme.surface, scrolledUnderElevation: 0),
      body: RefreshIndicator(
        onRefresh: () async => context.read<MenuProvider>().loadFavorites(),
        child: Builder(
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
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text('no_favorites_yet'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Display items
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.favoriteItems.length,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                final item = provider.favoriteItems[index];
                return MenuCard(item: item, onTap: () => _openDetail(context, item), onAddToCart: item.isAvailable ? () => context.read<CartProvider>().addToCart(item) : null);
              },
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, dynamic item) {
    context.push('/detail', extra: item);
  }
}
