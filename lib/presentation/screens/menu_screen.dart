import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/cards/menu_card.dart';
import 'package:urban_cafe/presentation/widgets/inputs/custom_search_bar.dart';

class MenuScreen extends StatefulWidget {
  final String? initialMainCategory;
  final bool focusSearch;
  const MenuScreen({super.key, this.initialMainCategory, this.focusSearch = false});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MenuProvider>();
      _searchCtrl.clear();

      if (widget.initialMainCategory != null) {
        await provider.initForMainCategory(widget.initialMainCategory!);
      } else {
        if (provider.items.isEmpty) {
          await provider.fetchAdminList();
        }
      }
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<MenuProvider>().loadMore();
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
            widget.initialMainCategory ?? 'menu'.tr(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
          ),
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        body: Column(
          children: [
            // 1. SEARCH BAR
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
              child: CustomSearchBar(controller: _searchCtrl, hintText: 'search'.tr(), onChanged: (v) => context.read<MenuProvider>().setSearch(v), onSubmitted: (v) => FocusScope.of(context).unfocus(), showFilter: true),
            ),

            // 2. HORIZONTAL CATEGORY CHIPS (Replacing the Modal)
            SizedBox(
              height: 50,
              child: Consumer<MenuProvider>(
                builder: (context, provider, child) {
                  final isLoadingCats = provider.loading && provider.subCategories.isEmpty;

                  // If purely empty (no data, not loading), hide
                  if (provider.subCategories.isEmpty && !isLoadingCats) {
                    return const SizedBox.shrink();
                  }

                  return Skeletonizer(
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
                  );
                },
              ),
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
                          : ListView.separated(
                              controller: _scrollCtrl,
                              cacheExtent: 2000, // Keep more items in memory to prevent smooth scrolling issues
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
                                  onTap: isLoadingInitial
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          context.push('/detail', extra: item);
                                        },
                                );
                              },
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
