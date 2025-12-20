import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/core/common_constants.dart';
//import 'package:urban_cafe/presentation/providers/auth_provider.dart';
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
  // 2. Define a variable to hold the Future
  late Future<List<CategoryObj>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    // 3. Initialize the Future only ONCE.
    // Use read() here, not watch(), because we only need to fetch the reference once.
    _categoriesFuture = context.read<MenuProvider>().getMainCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Note: If you need to listen to other changes in MenuProvider, keep this watch.
    // But for the categories list specifically, we rely on _categoriesFuture.
    final menuProvider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.admin_panel_settings_outlined, color: colorScheme.primary),
        //   tooltip: 'Admin Area',
        //   onPressed: () {
        //     final auth = context.read<AuthProvider>();
        //     if (!auth.isConfigured) {
        //       context.push('/admin/login');
        //     } else if (auth.isLoggedIn) {
        //       context.push('/admin');
        //     } else {
        //       context.push('/admin/login');
        //     }
        //   },
        // ),
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

                        // 4. Use the cached _categoriesFuture
                        FutureBuilder<List<CategoryObj>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            final isLoading = snapshot.connectionState == ConnectionState.waiting;

                            // 1. LOADING STATE: Show Skeleton
                            if (isLoading) {
                              return Skeletonizer(
                                enabled: true,
                                effect: ShimmerEffect(baseColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)),
                                child: Column(
                                  children: List.generate(4, (index) {
                                    return const _MenuButton(label: 'Delicious Category', icon: Icons.local_cafe_rounded, route: '');
                                  }),
                                ),
                              );
                            }

                            // 2. ERROR / EMPTY STATE: Fallback
                            final categories = snapshot.data ?? [];
                            if (categories.isEmpty) {
                              return const Column(
                                children: [
                                  _MenuButton(label: 'Coffee', icon: Icons.local_cafe_rounded, route: '/menu?initialMainCategory=Coffee'),
                                  _MenuButton(label: 'Drinks', icon: Icons.local_drink_rounded, route: '/menu?initialMainCategory=Drinks'),
                                  _MenuButton(label: 'Food', icon: Icons.restaurant_menu_rounded, route: '/menu?initialMainCategory=FOOD'),
                                  _MenuButton(label: 'Bread & Cakes', icon: Icons.bakery_dining_rounded, route: '/menu?initialMainCategory=Bread%20%26%20Cakes'),
                                ],
                              );
                            }

                            // 3. SUCCESS STATE: Real Data
                            return Column(
                              children: categories.map((cat) {
                                final encodedName = Uri.encodeComponent(cat.name);
                                // Note: Ensure menuProvider has this method or pass logic appropriately
                                final icon = menuProvider.getIconForCategory(cat.name);
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
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.secondaryContainer : colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [if (!isDark) BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary),
              const SizedBox(width: 20),
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 18, color: isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: (isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary).withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
