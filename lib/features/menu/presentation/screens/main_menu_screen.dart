import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/features/_common/widgets/cards/grid_menu_card.dart';
import 'package:urban_cafe/features/_common/widgets/cards/home_promo_banner.dart';
import 'package:urban_cafe/features/_common/widgets/inputs/custom_search_bar.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

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
    _fadeController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?.userMetadata?['full_name']?.split(' ').first;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadHomeData(),
          color: cs.primary,
          child: CustomScrollView(
            slivers: [
              // 1. GREETING HEADER with animation
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(_fadeAnimation),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getGreetingEmoji(),
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (userName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back, $userName!',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. SEARCH BAR with stagger delay
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Hero(
                      tag: 'search-bar-hero',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomSearchBar(
                          controller: _searchCtrl,
                          hintText: 'Search coffee, drinks...',
                          readOnly: true,
                          onTap: () => context.push('/menu?focusSearch=true'),
                          showFilter: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. PROMO BANNER with stagger delay
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Skeletonizer(
                    enabled: provider.loading,
                    child: HomePromoBanner(items: provider.specialItems),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // 4. CATEGORIES with stagger delay
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Categories",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: Skeletonizer(
                          enabled: provider.mainCategoriesLoading,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.mainCategories.isEmpty
                                ? 5
                                : provider.mainCategories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (provider.mainCategories.isEmpty) {
                                return const _CategoryChip(
                                  label: 'Loading...',
                                  isSelected: false,
                                  index: 0,
                                );
                              }
                              final cat = provider.mainCategories[index];
                              return _CategoryChip(
                                label: cat.name,
                                isSelected: false,
                                index: index,
                                onTap: () => context.push(
                                  '/menu?initialMainCategory=${Uri.encodeComponent(cat.name)}',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

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
                            Text(
                              "Popular Now",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.tertiary],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/menu'),
                          child: Text(
                            "View All",
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (provider.popularItems.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        }
                        return GridMenuCard(
                          item: provider.popularItems[index],
                          index: index, // Pass index for staggered animation
                        );
                      },
                      childCount: provider.popularItems.isEmpty
                          ? 4
                          : provider.popularItems.length,
                    ),
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
  final bool isSelected;
  final VoidCallback? onTap;
  final int index;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    this.onTap,
    this.index = 0,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    )
                  : null,
              color: widget.isSelected
                  ? null
                  : (isDark ? cs.surfaceContainerHighest : cs.surface),
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? null
                  : Border.all(
                      color: _isPressed
                          ? cs.primary.withValues(alpha: 0.5)
                          : cs.outlineVariant.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                else if (_isPressed)
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : cs.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
