import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/animations.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/features/_common/widgets/cards/grid_menu_card.dart';
import 'package:urban_cafe/features/_common/widgets/cards/home_promo_banner.dart';

import 'package:urban_cafe/features/_common/widgets/main_scaffold.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning';
    if (hour < 17) return 'good_afternoon';
    return 'good_evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();

    final userName = auth.profile?.fullName ?? (auth.isGuest ? 'Guest' : 'User');

    // Get scroll controller from MainScaffold if available
    final scrollScope = ScrollControllerScope.of(context);
    final scrollController = scrollScope?.scrollController;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadHomeData(),
          color: cs.primary,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // 1. GREETING HEADER with logo, user name, and search icon
              SliverToBoxAdapter(
                child: FadeSlideAnimation(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        // Logo
                        Image.asset('assets/logos/urbancafelogo.png', width: 56, height: 56, fit: BoxFit.contain),
                        const SizedBox(width: 16),
                        // Greeting and user name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting().tr(),
                                style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userName,
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                              ),
                            ],
                          ),
                        ),
                        // Search icon button
                        IconButton(
                          onPressed: () => context.push('/menu?focusSearch=true'),
                          icon: Icon(Icons.search_rounded, color: cs.onSurface),
                          style: IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5), padding: const EdgeInsets.all(12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. PROMO BANNER with stagger delay
              SliverToBoxAdapter(
                child: FadeSlideAnimation(
                  index: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("weekend_specials".tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ScaleTapWidget(
                              onTap: () => context.push('/menu?filter=special'),
                              child: Text(
                                "see_all".tr(),
                                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Skeletonizer(
                        enabled: provider.loading,
                        child: HomePromoBanner(items: provider.specialItems),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 4. CATEGORIES with stagger delay
              SliverToBoxAdapter(
                child: FadeSlideAnimation(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text("categories".tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: Skeletonizer(
                          enabled: provider.mainCategoriesLoading,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.mainCategories.isEmpty ? 5 : provider.mainCategories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (provider.mainCategories.isEmpty) {
                                return const _ShimmerCategoryChip();
                              }
                              final cat = provider.mainCategories[index];
                              return _CategoryChip(label: cat.name, icon: provider.getIconForCategory(cat.name), isSelected: false, index: index, onTap: () => context.go('/menu?initialMainCategory=${Uri.encodeComponent(cat.name)}'));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 5. POPULAR ITEMS HEADER
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text("most_popular".tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3)),
                              child: const Text('🔥', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/menu?filter=popular'),
                          child: Text(
                            "view_all".tr(),
                            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 6. POPULAR ITEMS GRID with index for staggered animation
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: Skeletonizer.sliver(
                  enabled: provider.loading,
                  child: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: Responsive.gridColumns(context), mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (provider.popularItems.isEmpty) {
                        return Container(
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                        );
                      }
                      return GridMenuCard(
                        item: provider.popularItems[index],
                        index: index, // Pass index for staggered animation
                      );
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

class _CategoryChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final int index;

  const _CategoryChip({required this.label, required this.icon, required this.isSelected, this.onTap, this.index = 0});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]) : null,
              color: widget.isSelected ? null : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.isSelected ? Colors.transparent : (_isPressed ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.2)), width: 1),
              boxShadow: [if (widget.isSelected) BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)) else BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: widget.isSelected ? Colors.white.withValues(alpha: 0.2) : cs.primaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: Icon(widget.icon, size: 20, color: widget.isSelected ? Colors.white : cs.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(color: widget.isSelected ? Colors.white : cs.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCategoryChip extends StatelessWidget {
  const _ShimmerCategoryChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 48,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
    );
  }
}
