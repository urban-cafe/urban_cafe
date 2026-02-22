import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/features/_common/theme_provider.dart';
import 'package:urban_cafe/features/_common/widgets/buttons/primary_button.dart';
import 'package:urban_cafe/features/_common/widgets/cards/profile_section_card.dart';
import 'package:urban_cafe/features/_common/widgets/dialogs/confirmation_dialog.dart';
import 'package:urban_cafe/features/_common/widgets/tiles/profile_action_tile.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;
    final user = auth.currentUser;
    final profile = auth.profile;

    final email = isGuest ? 'Guest' : (user?.email ?? 'Guest');
    final name = isGuest ? 'Guest User' : (profile?.fullName ?? email.split('@').first);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    // Responsive padding
    final sizeClass = Responsive.windowSizeClass(context);
    final horizontalPadding = switch (sizeClass) {
      WindowSizeClass.compact => 16.0,
      WindowSizeClass.medium => 32.0,
      WindowSizeClass.expanded => 48.0,
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primaryContainer, colorScheme.surface], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            initial,
                            style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      // Account section
                      if (!isGuest) ...[
                        ProfileSectionCard(
                          title: 'account'.tr(),
                          children: [ProfileActionTile(icon: Icons.edit_outlined, title: 'edit_profile'.tr(), subtitle: 'Update your name and details', onTap: () => context.push('/profile/edit'))],
                        ),
                      ],

                      ProfileSectionCard(
                        title: 'settings'.tr(),
                        children: [
                          ProfileActionTile(
                            icon: Icons.language,
                            title: 'language'.tr(),
                            subtitle: context.locale.languageCode == 'en' ? 'english'.tr() : 'myanmar'.tr(),
                            onTap: () => _showLanguageDialog(context),
                          ),
                          ProfileActionTile(icon: Icons.brightness_6_outlined, title: 'theme'.tr(), subtitle: _themeLabel(context), onTap: () => _showThemeDialog(context)),
                        ],
                      ),

                      // About Section
                      ProfileSectionCard(
                        title: 'about'.tr(),
                        children: [
                          ProfileActionTile(icon: Icons.info_outline, title: 'version'.tr(), subtitle: 'v$_version', trailing: const SizedBox.shrink()),
                          ProfileActionTile(icon: Icons.support_agent_rounded, title: 'Contact Us'.tr(), subtitle: 'Get in touch with us'.tr(), onTap: () => context.push('/profile/contact')),
                          ProfileActionTile(icon: Icons.system_update_outlined, title: 'check_for_updates'.tr(), subtitle: 'check_for_updates_subtitle'.tr(), onTap: () => _checkForUpdates(context)),
                        ],
                      ),

                      // Logout Button
                      PrimaryButton(text: 'sign_out'.tr(), onPressed: () => _confirmSignOut(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLang = context.locale.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(title: Text('choose_language'.tr()), children: [_langOption(ctx, 'English', 'en', currentLang), _langOption(ctx, 'Myanmar', 'my', currentLang)]),
    );
  }

  Widget _langOption(BuildContext ctx, String label, String code, String currentCode) {
    final isSelected = code == currentCode;
    final cs = Theme.of(ctx).colorScheme;
    return SimpleDialogOption(
      onPressed: () {
        ctx.setLocale(Locale(code));
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: isSelected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? cs.primary : null),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Theme Dialog ──────────────────────────────────────────────

  String _themeLabel(BuildContext context) {
    final mode = context.watch<ThemeProvider>().themeMode;
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final current = themeProvider.themeMode;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('theme'.tr()),
        children: [
          _themeOption(ctx, themeProvider, 'Light', ThemeMode.light, current),
          _themeOption(ctx, themeProvider, 'Dark', ThemeMode.dark, current),
          _themeOption(ctx, themeProvider, 'System', ThemeMode.system, current),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, ThemeProvider provider, String label, ThemeMode mode, ThemeMode current) {
    final isSelected = mode == current;
    final cs = Theme.of(ctx).colorScheme;
    return SimpleDialogOption(
      onPressed: () {
        provider.setThemeMode(mode);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: isSelected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? cs.primary : null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    // Simulate checking for updates
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking for updates...')));
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('up_to_date'.tr()),
          content: Text('You are using the latest version ($_version).'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ok'.tr()))],
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          ConfirmationDialog(title: 'sign_out'.tr(), message: 'sign_out_confirm'.tr(), confirmText: 'sign_out'.tr(), cancelText: 'cancel'.tr(), onConfirm: () => Navigator.pop(ctx, true)),
    );

    if (confirm == true && context.mounted) {
      context.read<AuthProvider>().signOut();
      context.go('/');
    }
  }
}
