import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/cards/grid_menu_card.dart';
import 'package:urban_cafe/presentation/widgets/inputs/custom_search_bar.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MenuProvider>();
      if (provider.popularItems.isEmpty || provider.specialItems.isEmpty) {
        provider.loadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?.userMetadata?['full_name']?.split(' ').first ?? 'Guest';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadHomeData(),
          child: CustomScrollView(
            slivers: [
              // 1. HEADER & SEARCH
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location / Greeting
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Location', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                              Row(
                                children: [
                                  Text(
                                    'Yangon, Myanmar',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 20),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Profile Image (or Initials)
                          InkWell(
                            onTap: () => context.go('/profile'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                image: user?.userMetadata?['avatar_url'] != null ? DecorationImage(image: NetworkImage(user!.userMetadata!['avatar_url']), fit: BoxFit.cover) : null,
                              ),
                              child: user?.userMetadata?['avatar_url'] == null ? Icon(Icons.person, color: cs.onSurfaceVariant) : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Search Bar
                      Hero(
                        tag: 'search-bar-hero',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomSearchBar(
                            controller: _searchCtrl,
                            hintText: 'Search coffee, drinks...',
                            readOnly: true, // Navigate to full search page on tap
                            onTap: () => context.push('/menu?focusSearch=true'),
                            showFilter: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. PROMO BANNER
              SliverToBoxAdapter(
                child: Skeletonizer(
                  enabled: provider.loading,
                  child: _PromoBanner(item: provider.specialItems.isNotEmpty ? provider.specialItems.first : null),
                ),
              ),

              // 3. CATEGORIES (Horizontal)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text("Categories", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: Skeletonizer(
                          enabled: provider.mainCategoriesLoading,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.mainCategories.isEmpty ? 5 : provider.mainCategories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (provider.mainCategories.isEmpty) {
                                return const _CategoryChip(label: 'Loading...', isSelected: false);
                              }
                              final cat = provider.mainCategories[index];
                              return _CategoryChip(
                                label: cat.name,
                                isSelected: index == 0, // Highlight first for visual
                                onTap: () => context.push('/menu?initialMainCategory=${Uri.encodeComponent(cat.name)}'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. POPULAR ITEMS (Grid)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text("Popular Now", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // Bottom padding for FAB
                sliver: Skeletonizer.sliver(
                  enabled: provider.loading,
                  child: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75, // Taller cards
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (provider.popularItems.isEmpty) {
                        // Show placeholder if empty or loading
                        return Container(
                          decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
                        );
                      }
                      return GridMenuCard(item: provider.popularItems[index]);
                    }, childCount: provider.popularItems.isEmpty ? 4 : provider.popularItems.length),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final dynamic item; // Can be MenuItemEntity or null

  const _PromoBanner({this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 160,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
        image: item?.imageUrl != null ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken)) : null,
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional)
          if (item?.imageUrl == null) Positioned(right: -20, bottom: -20, child: Icon(Icons.local_cafe, size: 180, color: Colors.white.withValues(alpha: 0.1))),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Promo',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item != null ? 'Weekend Special:\n${item.name}' : 'Buy one get\none FREE',
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryChip({required this.label, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? cs.primary : (cs.surfaceContainerHigh.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : cs.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600),
        ),
      ),
    );
  }
}
