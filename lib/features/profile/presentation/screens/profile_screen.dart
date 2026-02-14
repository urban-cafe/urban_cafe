import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/core/routing/routes.dart';
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
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
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
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Account section
                      if (auth.isClient && !isGuest) ...[
                        ProfileSectionCard(
                          title: 'account'.tr(),
                          children: [
                            ProfileActionTile(icon: Icons.edit_outlined, title: 'edit_profile'.tr(), subtitle: 'Update your name and details', onTap: () => context.push('/profile/edit')),
                            ProfileActionTile(icon: Icons.receipt_long_outlined, title: 'order_history'.tr(), subtitle: 'View past orders', onTap: () => context.push('/profile/orders')),
                            ProfileActionTile(
                              icon: Icons.favorite_border_rounded,
                              title: 'favorites'.tr(),
                              subtitle: 'Your saved items',
                              iconColor: Colors.redAccent,
                              onTap: () => context.push('/profile/favorites'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Staff/Admin Management Section
                      if (auth.isStaff || auth.isAdmin) ...[
                        ProfileSectionCard(
                          title: 'management'.tr(),
                          children: [
                            ProfileActionTile(
                              icon: Icons.point_of_sale,
                              title: 'Point of Sale',
                              subtitle: 'Sell items directly',
                              iconColor: const Color(0xFF2E7D32),
                              onTap: () => context.push(AppRoutes.pos),
                            ),
                            if (auth.isStaff)
                              ProfileActionTile(
                                icon: Icons.soup_kitchen_outlined,
                                title: 'kitchen_display'.tr(),
                                subtitle: 'Manage active orders',
                                iconColor: Colors.orange,
                                onTap: () => context.push(AppRoutes.staff),
                              ),
                            if (auth.isAdmin) ...[
                              ProfileActionTile(
                                icon: Icons.dashboard_outlined,
                                title: 'admin_dashboard'.tr(),
                                subtitle: 'Manage menu items',
                                iconColor: Colors.purple,
                                onTap: () => context.push(AppRoutes.admin),
                              ),
                              if (auth.isAdmin)
                                ProfileActionTile(
                                  // Separate check just in case logic changes
                                  icon: Icons.analytics_outlined,
                                  title: 'Analytics',
                                  subtitle: 'View sales performance',
                                  iconColor: Colors.blue,
                                  onTap: () => context.push('${AppRoutes.admin}/analytics'),
                                ),
                              ProfileActionTile(
                                icon: Icons.settings_input_component_outlined,
                                title: 'point_settings'.tr(),
                                subtitle: 'Configure loyalty points',
                                iconColor: Colors.teal,
                                onTap: () => context.push(AppRoutes.adminPointSettings),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Settings Section
                      ProfileSectionCard(
                        title: 'settings'.tr(),
                        children: [
                          ProfileActionTile(
                            icon: Icons.language,
                            title: 'language'.tr(),
                            subtitle: context.locale.languageCode == 'en' ? 'English' : 'Myanmar',
                            onTap: () => context.push('/profile/language'),
                          ),
                          ProfileActionTile(icon: Icons.brightness_6_outlined, title: 'theme'.tr(), subtitle: 'Change app appearance', onTap: () => context.push('/profile/theme')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // About Section
                      ProfileSectionCard(
                        title: 'about'.tr(),
                        children: [
                          ProfileActionTile(icon: Icons.info_outline, title: 'version'.tr(), subtitle: 'v$_version', trailing: const SizedBox.shrink()),
                          ProfileActionTile(icon: Icons.system_update_outlined, title: 'check_for_updates'.tr(), subtitle: 'check_for_updates_subtitle'.tr(), onTap: () => _checkForUpdates(context)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      PrimaryButton(text: 'sign_out'.tr(), onPressed: () => _confirmSignOut(context)),

                      const SizedBox(height: 100), // Bottom padding for navigation bar
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
