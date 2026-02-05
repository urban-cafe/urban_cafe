import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/_common/widgets/cards/loyalty_card.dart';
import 'package:urban_cafe/features/_common/widgets/cards/profile_header.dart';
import 'package:urban_cafe/features/_common/widgets/cards/profile_section_card.dart';
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
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUserEmail ?? 'Guest';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
    final role = auth.role.name.toUpperCase();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text('profile'.tr()), centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ProfileHeader(email: email, role: role, initial: initial),

                  if (auth.isClient) ...[const SizedBox(height: 20), LoyaltyCard(points: auth.loyaltyPoints, onTap: () {})],

                  const SizedBox(height: 24),

                  if (auth.isClient)
                    ProfileSectionCard(
                      title: 'Account',
                      children: [
                        ProfileActionTile(icon: Icons.history_rounded, title: 'order_history'.tr(), subtitle: 'View past orders', onTap: () => context.push('/profile/orders')),
                        ProfileActionTile(icon: Icons.favorite_rounded, title: 'Favorites', subtitle: 'Your saved items', iconColor: Colors.redAccent, onTap: () => context.push('/profile/favorites')),
                      ],
                    ),

                  if (auth.isStaff || auth.isAdmin)
                    ProfileSectionCard(
                      title: 'Management',
                      children: [
                        if (auth.isStaff) ProfileActionTile(icon: Icons.kitchen_rounded, title: 'kitchen_display'.tr(), subtitle: 'Manage active orders', iconColor: Colors.orange, onTap: () => context.push('/staff')),
                        if (auth.isAdmin) ...[ProfileActionTile(icon: Icons.dashboard_rounded, title: 'admin_dashboard'.tr(), subtitle: 'Manage menu items', iconColor: Colors.purple, onTap: () => context.push('/admin')), ProfileActionTile(icon: Icons.analytics_outlined, title: 'Analytics', subtitle: 'View sales performance', iconColor: Colors.blue, onTap: () => context.push('/admin/analytics'))],
                      ],
                    ),

                  ProfileSectionCard(
                    title: 'Settings',
                    children: [
                      ProfileActionTile(icon: Icons.language_rounded, title: 'language'.tr(), subtitle: context.locale.languageCode == 'en' ? 'English' : 'Myanmar', onTap: () => context.push('/profile/language')),
                      ProfileActionTile(icon: Icons.brightness_6_rounded, title: 'theme'.tr(), subtitle: 'Change app appearance', onTap: () => context.push('/profile/theme')),
                    ],
                  ),

                  ProfileSectionCard(
                    title: 'About',
                    children: [
                      ProfileActionTile(icon: Icons.info_outline, title: 'Version', subtitle: 'v$_version', trailing: const SizedBox.shrink()),
                      ProfileActionTile(icon: Icons.system_update, title: 'Check for Updates', subtitle: 'Check for latest version', onTap: () => _checkForUpdates(context)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: Text('sign_out'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.outline),
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _confirmSignOut(context),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
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
          title: const Text('Up to Date'),
          content: Text('You are using the latest version ($_version).'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('sign_out'.tr()),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text('sign_out'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<AuthProvider>().signOut();
      context.go('/');
    }
  }
}
