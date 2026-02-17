import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/animations.dart' hide ShimmerEffect;
import 'package:urban_cafe/features/_common/widgets/cards/menu_card.dart';
import 'package:urban_cafe/features/_common/widgets/inputs/custom_search_bar.dart';
import 'package:urban_cafe/features/_common/widgets/main_scaffold.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

class MenuScreen extends StatefulWidget {
  final String? initialMainCategory;
  final String? filter; // 'popular' or 'special'
  final bool focusSearch;
  const MenuScreen({super.key, this.initialMainCategory, this.filter, this.focusSearch = false});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isGridView = true; // Toggle state
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MenuProvider>();
      _searchCtrl.clear();

      if (widget.filter != null) {
        await provider.initForFilter(widget.filter!);
      } else if (widget.initialMainCategory != null) {
        await provider.initForMainCategory(widget.initialMainCategory!);
      } else {
        if (provider.items.isEmpty || provider.searchQuery.isNotEmpty) {
          await provider.fetchAdminList();
        }
      }
    });

    _scrollCtrl.addListener(() {
      // Pagination
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<MenuProvider>().loadMore();
      }

      // Dynamic Nav Bar
      final scope = ScrollControllerScope.of(context);
      if (scope != null && _scrollCtrl.hasClients) {
        final currentOffset = _scrollCtrl.offset;
        // Ignore bounces at top/bottom
        if (currentOffset < 0 || currentOffset > _scrollCtrl.position.maxScrollExtent) return;

        final diff = currentOffset - _lastScrollOffset;
        if (diff.abs() > 20) {
          // Threshold
          if (diff > 0) {
            scope.onScrollDown?.call(); // Hide
          } else {
            scope.onScrollUp?.call(); // Show
          }
          _lastScrollOffset = currentOffset;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    // We can't easily access context in dispose to reset search,
    // but MenuProvider handles reset on init anyway.
    super.dispose();
  }

  MenuItemEntity get _dummyItem => MenuItemEntity(id: 'dummy', name: 'Loading...', description: '...', price: 0, categoryId: null, categoryName: '', imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

  String get _title {
    if (widget.filter == 'popular') return 'most_popular'.tr();
    if (widget.filter == 'special') return 'weekend_specials'.tr();
    return widget.initialMainCategory ?? 'menu'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        FocusScope.of(context).unfocus();
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            _title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
          ),
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        body: Column(
          children: [
            // 1. SEARCH BAR + VIEW TOGGLE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(controller: _searchCtrl, hintText: 'search'.tr(), onChanged: (v) => context.read<MenuProvider>().setSearch(v), onSubmitted: (v) => FocusScope.of(context).unfocus(), showFilter: true),
                  ),
                  const SizedBox(width: 12),
                  // View Toggle Button
                  ScaleTapWidget(
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: child.key == const ValueKey('grid') ? Tween<double>(begin: 0.75, end: 1).animate(anim) : Tween<double>(begin: 0.75, end: 1).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, key: ValueKey(_isGridView ? 'list' : 'grid'), color: colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. HORIZONTAL CATEGORY CHIPS (Replacing the Modal)
            Consumer<MenuProvider>(
              builder: (context, provider, child) {
                final isLoadingCats = provider.loading && provider.subCategories.isEmpty;

                // If purely empty (no data, not loading), hide
                if (provider.subCategories.isEmpty && !isLoadingCats) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  height: 50,
                  child: Skeletonizer(
                    enabled: isLoadingCats,
                    effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      // Show 5 dummy chips if loading, otherwise real count + "All"
                      itemCount: isLoadingCats ? 5 : provider.subCategories.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        // SKELETON CHIP
                        if (isLoadingCats) {
                          return ChoiceChip(
                            label: const Text("Loading Cat"), // Placeholder text for width
                            selected: false,
                            showCheckmark: false,
                            labelStyle: textTheme.bodyMedium,
                            backgroundColor: colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            onSelected: (_) {},
                          );
                        }

                        // REAL DATA
                        final isAll = index == 0;
                        final cat = isAll ? null : provider.subCategories[index - 1];
                        // Use Provider state directly
                        final isSelected = isAll ? provider.currentCategoryId == null : provider.currentCategoryId == cat!.id;

                        return ChoiceChip(
                          label: Text(isAll ? "all".tr() : cat!.name),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          backgroundColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: isSelected ? Colors.transparent : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              // NO setState here! Provider notifies listeners.
                              provider.filterBySubCategory(isAll ? null : cat!.id);
                            }
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            //const Divider(height: 1, indent: 16, endIndent: 16),

            // 3. MENU ITEMS LIST
            Expanded(
              child: Consumer<MenuProvider>(
                builder: (context, provider, child) {
                  final isLoadingInitial = provider.loading && provider.items.isEmpty;
                  final displayItems = isLoadingInitial ? List.generate(6, (index) => _dummyItem) : provider.items;

                  return RefreshIndicator(
                    onRefresh: () async {
                      if (widget.initialMainCategory != null) {
                        await provider.initForMainCategory(widget.initialMainCategory!);
                      } else {
                        await provider.fetchAdminList();
                      }
                    },
                    child: Skeletonizer(
                      enabled: isLoadingInitial,
                      effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                      child: provider.items.isEmpty && !isLoadingInitial
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64, color: colorScheme.outlineVariant),
                                  const SizedBox(height: 16),
                                  Text('no_items_found'.tr(), style: textTheme.bodyLarge),
                                ],
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isGridView
                                  ? GridView.builder(
                                      key: const ValueKey('grid_view'),
                                      controller: _scrollCtrl,
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.75, // Adjust for card height
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                      ),
                                      itemCount: displayItems.length + (provider.loadingMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == displayItems.length) {
                                          return Skeletonizer(enabled: true, child: _MenuGridItem(item: _dummyItem));
                                        }
                                        final item = displayItems[index];
                                        return _MenuGridItem(
                                          item: item,
                                          index: index,
                                          onTap: isLoadingInitial
                                              ? null
                                              : () {
                                                  FocusScope.of(context).unfocus();
                                                  context.push('/detail', extra: item);
                                                },
                                          onAddToCart: isLoadingInitial || !item.isAvailable ? null : () => context.read<CartProvider>().addToCart(item),
                                        );
                                      },
                                    )
                                  : ListView.separated(
                                      key: const ValueKey('list_view'),
                                      controller: _scrollCtrl,
                                      cacheExtent: 2000,
                                      padding: const EdgeInsets.only(top: 8, bottom: 32),
                                      itemCount: displayItems.length + (provider.loadingMore ? 1 : 0),
                                      separatorBuilder: (_, _) => Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                      itemBuilder: (context, index) {
                                        if (index == displayItems.length) {
                                          return Skeletonizer(enabled: true, child: MenuCard(item: _dummyItem, onTap: null));
                                        }

                                        final item = displayItems[index];
                                        return MenuCard(
                                          item: item,
                                          index: index,
                                          onTap: isLoadingInitial
                                              ? null
                                              : () {
                                                  FocusScope.of(context).unfocus();
                                                  context.push('/detail', extra: item);
                                                },
                                          onAddToCart: isLoadingInitial || !item.isAvailable ? null : () => context.read<CartProvider>().addToCart(item),
                                        );
                                      },
                                    ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty) return const SizedBox.shrink();
            return FloatingActionButton.extended(onPressed: () => context.push('/cart'), backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, icon: const Icon(Icons.shopping_cart), label: Text('${cart.itemCount} items'));
          },
        ),
      ),
    );
  }
}

class _MenuGridItem extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int index;

  const _MenuGridItem({required this.item, this.onTap, this.onAddToCart, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final priceFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final isFavorite = context.select<MenuProvider, bool>((p) => p.favoriteIds.contains(item.id));
    final isGuest = auth.isGuest;

    return ScaleTapWidget(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with Favorite
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: cs.surfaceContainerHighest),
                            errorWidget: (_, _, _) => Icon(Icons.fastfood, color: cs.onSurfaceVariant),
                          )
                        : Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.restaurant, color: cs.onSurfaceVariant),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => context.read<MenuProvider>().toggleFavorite(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                        child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : cs.onSurface, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.categoryName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.categoryName!,
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          priceFormat.format(item.price),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                        if (!item.isAvailable || onAddToCart == null)
                          const SizedBox.shrink()
                        else if (!isGuest)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
