import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';
import 'package:urban_cafe/presentation/widgets/social_link_button.dart'; // Import this

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

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
        leading: IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: colorScheme.primary),
          tooltip: 'Toggle Theme',
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings_outlined, color: colorScheme.primary),
            tooltip: 'Admin Area',
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isConfigured) {
                context.go('/admin/login');
              } else if (auth.isLoggedIn) {
                context.go('/admin');
              } else {
                context.go('/admin/login');
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // FIX: Allow scrolling if content overflows
            child: ConstrainedBox(
              // FIX: Ensure content fills at least the screen height to keep centering working
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // REPLACED Spacer with SizedBox to prevent scroll errors
                        const SizedBox(height: 24),

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

                        const SizedBox(height: 48),

                        const _MenuButton(label: 'HOT DRINKS', icon: Icons.local_cafe_rounded, route: '/menu?initialMainCategory=HOT%20DRINKS'),
                        const _MenuButton(label: 'COLD DRINKS', icon: Icons.local_drink_rounded, route: '/menu?initialMainCategory=COLD%20DRINKS'),
                        const _MenuButton(label: 'FOOD', icon: Icons.restaurant_menu_rounded, route: '/menu?initialMainCategory=FOOD'),

                        // REPLACED Spacer with fixed spacing
                        const SizedBox(height: 48),

                        Text(
                          "Follow Us",
                          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialLinkButton(icon: FontAwesomeIcons.tiktok, url: 'https://www.tiktok.com/@urbantea.mm?_r=1&_t=ZS-9206DYuBDJQ'),
                            SizedBox(width: 16),
                            SocialLinkButton(icon: FontAwesomeIcons.facebookF, url: 'https://www.facebook.com/urbantea915?mibextid=wwXIfr'),
                            SizedBox(width: 16),
                            SocialLinkButton(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/urbantea.mm?igsh=MTJjeHpjMXhnODduag=='),
                          ],
                        ),
                        const SizedBox(height: 32),
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

// Extracted private widget for cleaner code and caching
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
          height: 68,
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
