import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MenuProvider>();

      _searchCtrl.clear();
      provider.setSearch('');

      if (widget.initialMainCategory != null) {
        provider.initForMainCategory(widget.initialMainCategory!);
      } else {
        provider.fetchAdminList();
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
    super.dispose();
  }

  void _showCategorySelector(BuildContext context) {
    final provider = context.read<MenuProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    // FIX: Use withValues(alpha: ...) instead of withOpacity
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Select Category",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCategoryTile(
                        ctx,
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

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.subCategories.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final cat = provider.subCategories[index];
                          return _buildCategoryTile(
                            ctx,
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
                          );
                        },
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

  Widget _buildCategoryTile(BuildContext context, {required String label, required bool isSelected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // FIX: Use withValues(alpha: ...) instead of withOpacity
        color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? colorScheme.primary : colorScheme.onSurface, letterSpacing: 0.5),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.initialMainCategory ?? 'Menu',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
        ),
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (provider.subCategories.isNotEmpty)
                  InkWell(
                    onTap: () => _showCategorySelector(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                        // FIX: Use withValues(alpha: ...) instead of withOpacity
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedSubName, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
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
                      onChanged: (v) => provider.setSearch(v),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: provider.loading && provider.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: provider.items.length + (provider.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      if (index == provider.items.length) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                        );
                      }

                      final item = provider.items[index];
                      return MenuCard(
                        item: item,
                        onTap: () => context.push('/detail', extra: item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
