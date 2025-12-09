import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/category_sheet_tile.dart'; // Import this
import 'package:urban_cafe/presentation/widgets/menu_card.dart';

class MenuScreen extends StatefulWidget {
  final String? initialMainCategory;
  const MenuScreen({super.key, this.initialMainCategory});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _selectedSubId;
  String _selectedSubName = 'All';
  late MenuProvider menuProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      menuProvider = Provider.of<MenuProvider>(context, listen: false);
      _searchCtrl.clear();

      if (widget.initialMainCategory != null) {
        await menuProvider.initForMainCategory(widget.initialMainCategory!);
      } else {
        await menuProvider.fetchAdminList();
      }
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        menuProvider.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    menuProvider.resetSearch("");
    log("Menu Lists Dispose");
    super.dispose();
  }

  // Moved Dummy Data to a static helper or keep here if simple
  MenuItemEntity get _dummyItem => MenuItemEntity(id: 'dummy', name: 'Loading Item ...', description: 'Loading description ...', price: 0, categoryId: null, categoryName: 'Category', imagePath: null, imageUrl: null, isAvailable: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

  void _showCategorySelector(BuildContext context) {
    final provider = context.read<MenuProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategorySheetTile(
                        label: 'All',
                        isSelected: _selectedSubId == null,
                        onTap: () {
                          setState(() {
                            _selectedSubId = null;
                            _selectedSubName = 'All';
                          });
                          provider.filterBySubCategory(null);
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      // Access the list directly from the provider instance we captured
                      ...provider.subCategories.map(
                        (cat) => Column(
                          children: [
                            CategorySheetTile(
                              label: cat.name,
                              isSelected: _selectedSubId == cat.id,
                              onTap: () {
                                setState(() {
                                  _selectedSubId = cat.id;
                                  _selectedSubName = cat.name;
                                });
                                provider.filterBySubCategory(cat.id);
                                Navigator.pop(ctx);
                              },
                            ),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false, // 1. PREVENT the default system pop
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Safety check (should be false now)

        // 2. Perform your custom actions
        FocusScope.of(context).unfocus(); // Close keyboard first
        context.go('/'); // Navigate to Main Menu
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.initialMainCategory ?? 'Menu',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
          ),
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // SELECTOR: Only rebuilds if subCategories availability changes
                      Selector<MenuProvider, bool>(
                        selector: (_, provider) => provider.subCategories.isNotEmpty,
                        builder: (context, hasCategories, child) {
                          if (!hasCategories) return const SizedBox.shrink();
                          return InkWell(
                            onTap: () => _showCategorySelector(context),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_selectedSubName, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 18, color: colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16), isDense: true),
                            // Using read() ensures typing doesn't rebuild this widget itself
                            onChanged: (v) => menuProvider.setSearch(v),
                            onSubmitted: (v) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CONSUMER: Only this part rebuilds when data changes
                Expanded(
                  child: Consumer<MenuProvider>(
                    builder: (context, provider, child) {
                      final isLoadingInitial = provider.loading && provider.items.isEmpty;
                      final displayItems = isLoadingInitial ? List.generate(8, (index) => _dummyItem) : provider.items;

                      return Skeletonizer(
                        enabled: isLoadingInitial,
                        effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), highlightColor: colorScheme.surface),
                        child: provider.items.isEmpty && !isLoadingInitial
                            ? const Center(child: Text('No items found'))
                            : ListView.separated(
                                controller: _scrollCtrl,
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: displayItems.length + (provider.loadingMore ? 1 : 0),
                                separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
