import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/animations.dart' hide ShimmerEffect;
import 'package:urban_cafe/features/_common/widgets/cards/grid_menu_card.dart';
import 'package:urban_cafe/features/_common/widgets/cards/menu_card.dart';
import 'package:urban_cafe/features/_common/widgets/inputs/custom_search_bar.dart';
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
  bool _isGridView = true;
  late MenuProvider _menuProvider; // Cached ref — safe to call in dispose()

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _menuProvider = context.read<MenuProvider>(); // Cache before any async gap
      _searchCtrl.clear();

      // Always reinitialize — ensures fresh data every time the screen is entered,
      // even if we are returning from a previous visit with stale cached state.
      if (widget.filter != null) {
        await _menuProvider.initForFilter(widget.filter!);
      } else if (widget.initialMainCategory != null) {
        await _menuProvider.initForMainCategory(widget.initialMainCategory!);
      } else {
        await _menuProvider.fetchAdminList();
      }
    });

    _scrollCtrl.addListener(() {
      // Pagination
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<MenuProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _menuProvider.resetMenuState();
    super.dispose();
  }

  MenuItemEntity get _dummyItem => MenuItemEntity(
    id: 'dummy',
    name: 'Loading...',
    description: '...',
    price: 0,
    categoryId: null,
    categoryName: '',
    imagePath: null,
    imageUrl: null,
    isAvailable: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

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
        _menuProvider.resetMenuState();
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
                    child: CustomSearchBar(
                      controller: _searchCtrl,
                      hintText: 'search'.tr(),
                      onChanged: (v) => context.read<MenuProvider>().setSearch(v),
                      onSubmitted: (v) => FocusScope.of(context).unfocus(),
                      showFilter: true,
                    ),
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
                      final provider = context.read<MenuProvider>();
                      if (widget.filter != null) {
                        await provider.initForFilter(widget.filter!);
                      } else if (widget.initialMainCategory != null) {
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
                                  ? CustomScrollView(
                                      key: const ValueKey('grid_view'),
                                      controller: _scrollCtrl,
                                      slivers: [
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                          sliver: SliverGrid.builder(
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, mainAxisSpacing: 12, crossAxisSpacing: 12),
                                            itemCount: displayItems.length + (provider.loadingMore ? 1 : 0),
                                            itemBuilder: (context, index) {
                                              if (index == displayItems.length && provider.loadingMore) {
                                                return Skeletonizer(enabled: true, child: GridMenuCard(item: _dummyItem, index: -1));
                                              }
                                              final item = displayItems[index];
                                              return GridMenuCard(item: item, index: index);
                                            },
                                          ),
                                        ),
                                        if (!provider.hasMore && displayItems.isNotEmpty)
                                          const SliverToBoxAdapter(
                                            child: Padding(padding: EdgeInsets.only(bottom: 32), child: _EndOfListIndicator()),
                                          ),
                                      ],
                                    )
                                  : ListView.builder(
                                      key: const ValueKey('list_view'),
                                      controller: _scrollCtrl,
                                      cacheExtent: 2000,
                                      addAutomaticKeepAlives: false,
                                      padding: const EdgeInsets.only(top: 8, bottom: 32),
                                      itemCount: displayItems.length + (provider.loadingMore ? 1 : 0) + (!provider.hasMore && displayItems.isNotEmpty ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == displayItems.length && provider.loadingMore) {
                                          return Skeletonizer(enabled: true, child: MenuCard(item: _dummyItem, onTap: null));
                                        }
                                        if (index >= displayItems.length) {
                                          return const _EndOfListIndicator();
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
      ),
    );
  }
}

class _EndOfListIndicator extends StatelessWidget {
  const _EndOfListIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        Icon(Icons.coffee_outlined, size: 16, color: cs.outlineVariant),
        const SizedBox(width: 8),
        Text('no_more_items'.tr(), style: tt.bodySmall?.copyWith(color: cs.outlineVariant)),
        const SizedBox(width: 8),
        Icon(Icons.coffee_outlined, size: 16, color: cs.outlineVariant),
      ],
    );
  }
}
