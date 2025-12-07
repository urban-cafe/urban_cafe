import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Widget _socialButton(BuildContext context, IconData icon, String url) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: FaIcon(icon, size: 22),
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _menuButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 68, // REDUCED: Smaller height for a cleaner look (was 80)
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.secondaryContainer : colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [if (!isDark) BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28, // Slightly smaller icon to match new height
                color: isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary,
              ),
              const SizedBox(width: 20),
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 18, // Adjusted font size slightly
                  color: isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: (isDark ? colorScheme.onSecondaryContainer : colorScheme.onPrimary).withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
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
        leading: IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: colorScheme.primary),
          tooltip: 'Toggle Theme',
          onPressed: () {
            context.read<ThemeProvider>().toggleTheme();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings_outlined, color: colorScheme.primary),
            tooltip: 'Admin Area',
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isConfigured) {
                context.go('/admin/login');
                return;
              }
              if (auth.isLoggedIn) {
                context.go('/admin');
              } else {
                context.go('/admin/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/logos/urbancafelogo.png',
                    height: 220,
                    fit: BoxFit.contain,
                    color: isDark ? colorScheme.onSecondaryContainer : null,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.local_cafe, size: 100, color: colorScheme.primary),
                  ),
                ),

                const SizedBox(height: 48),

                _menuButton(context, label: 'HOT DRINKS', icon: Icons.local_cafe_rounded, onTap: () => context.push('/menu?initialMainCategory=HOT%20DRINKS')),
                _menuButton(context, label: 'COLD DRINKS', icon: Icons.local_drink_rounded, onTap: () => context.push('/menu?initialMainCategory=COLD%20DRINKS')),
                _menuButton(context, label: 'FOOD', icon: Icons.restaurant_menu_rounded, onTap: () => context.push('/menu?initialMainCategory=FOOD')),

                const Spacer(flex: 2),

                Text(
                  "Follow Us",
                  style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Playfair Display'),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [_socialButton(context, FontAwesomeIcons.tiktok, 'https://www.tiktok.com/@urbantea.mm?_r=1&_t=ZS-9206DYuBDJQ'), const SizedBox(width: 16), _socialButton(context, FontAwesomeIcons.facebookF, 'https://www.facebook.com/urbantea915?mibextid=wwXIfr'), const SizedBox(width: 16), _socialButton(context, FontAwesomeIcons.instagram, 'https://www.instagram.com/urbantea.mm?igsh=MTJjeHpjMXhnODduag==')]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
