import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/common_constants.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/widgets/contact_info_sheet.dart';
import 'package:urban_cafe/presentation/widgets/social_link_button.dart';
import 'package:urban_cafe/presentation/widgets/theme_selection_button.dart';

// 1. Change to StatefulWidget
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger load on init. Data is stored in Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMainCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Removed leading Profile Icon as it is now in BottomNavBar
        actions: const [ThemeSelectionButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/logos/urbancafelogo.png',
                            height: 220,
                            fit: BoxFit.contain,
                            color: isDark ? colorScheme.onSecondaryContainer : null,
                            errorBuilder: (_, _, _) => Icon(Icons.local_cafe, size: 100, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Use Consumer instead of FutureBuilder
                        Consumer<MenuProvider>(
                          builder: (context, menu, child) {
                            // 1. LOADING STATE
                            if (menu.mainCategoriesLoading && menu.mainCategories.isEmpty) {
                              return Skeletonizer(
                                enabled: true,
                                effect: ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), highlightColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)),
                                child: Column(
                                  children: List.generate(4, (index) {
                                    return const _MenuButton(label: 'Delicious Category', icon: Icons.local_cafe_rounded, route: '');
                                  }),
                                ),
                              );
                            }

                            // 2. ERROR / EMPTY STATE
                            if (menu.mainCategories.isEmpty) {
                              return const Column(
                                children: [
                                  _MenuButton(label: 'Coffee', icon: Icons.local_cafe_rounded, route: '/menu?initialMainCategory=Coffee'),
                                  _MenuButton(label: 'Drinks', icon: Icons.local_drink_rounded, route: '/menu?initialMainCategory=Drinks'),
                                  _MenuButton(label: 'Food', icon: Icons.restaurant_menu_rounded, route: '/menu?initialMainCategory=FOOD'),
                                  _MenuButton(label: 'Bread & Cakes', icon: Icons.bakery_dining_rounded, route: '/menu?initialMainCategory=Bread%20%26%20Cakes'),
                                ],
                              );
                            }

                            // 3. SUCCESS STATE
                            return Column(
                              children: menu.mainCategories.map((cat) {
                                final encodedName = Uri.encodeComponent(cat.name);
                                final icon = menu.getIconForCategory(cat.name);
                                return _MenuButton(label: cat.name, icon: icon, route: '/menu?initialMainCategory=$encodedName');
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialLinkButton(icon: FontAwesomeIcons.tiktok, url: CommonConstants.tiktokUrl),
                            SizedBox(width: 16),
                            SocialLinkButton(icon: FontAwesomeIcons.facebookF, url: CommonConstants.facebookUrl),
                            SizedBox(width: 16),
                            SocialLinkButton(icon: FontAwesomeIcons.instagram, url: CommonConstants.instagramUrl),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _showContactSheet(context),
                          label: const Text('Contact Us'),
                          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(onPressed: () => context.push('/cart'), backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, icon: const Icon(Icons.shopping_cart), label: Text('${cart.itemCount} items'));
        },
      ),
    );
  }
}

// ... Keep existing _showContactSheet and _MenuButton code ...
void _showContactSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const ContactInfoSheet(),
  );
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _MenuButton({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 80, // Taller button
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isDark ? [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainer] : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24), // More rounded
          boxShadow: [BoxShadow(color: (isDark ? Colors.black : colorScheme.primary).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(route),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(icon, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 20, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
