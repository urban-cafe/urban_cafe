import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch orders if client to show history (optional, now we have a separate screen)
    // But we might still want to show a summary or recent orders count
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUserEmail ?? 'Guest';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
    final role = auth.role.name.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. PROFILE HEADER
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initial,
                      style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(email, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      role,
                      style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loyalty Points Card (Only for Clients)
                  if (auth.isClient)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade300, Colors.amber.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.brown, size: 32),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                '${auth.loyaltyPoints}',
                                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.brown),
                              ),
                              Text(
                                'Loyalty Points',
                                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.brown.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. SETTINGS LIST
            // Client Features
            if (auth.isClient) ...[_ProfileTile(icon: Icons.history, title: 'order_history'.tr(), subtitle: 'View past orders', onTap: () => context.push('/profile/orders')), const SizedBox(height: 8), _ProfileTile(icon: Icons.favorite, title: 'Favorites', subtitle: 'Your saved items', onTap: () => context.push('/profile/favorites')), const SizedBox(height: 8)],

            // Staff/Admin Features
            if (auth.isStaff) ...[_ProfileTile(icon: Icons.kitchen, title: 'kitchen_display'.tr(), subtitle: 'Manage active orders', onTap: () => context.push('/staff')), const SizedBox(height: 8)],
            if (auth.isAdmin) ...[_ProfileTile(icon: Icons.dashboard, title: 'admin_dashboard'.tr(), subtitle: 'Manage menu items', onTap: () => context.push('/admin')), const SizedBox(height: 8), _ProfileTile(icon: Icons.analytics_outlined, title: 'Analytics', subtitle: 'View sales performance', onTap: () => context.push('/admin/analytics')), const SizedBox(height: 8), _ProfileTile(icon: Icons.category_outlined, title: 'Categories', subtitle: 'Manage menu categories', onTap: () => context.push('/admin/categories')), const SizedBox(height: 8), _ProfileTile(icon: Icons.receipt_long, title: 'all_orders'.tr(), subtitle: 'View all system orders', onTap: () => context.push('/admin/orders')), const SizedBox(height: 8), _ProfileTile(icon: Icons.kitchen_outlined, title: 'kitchen_display'.tr(), subtitle: 'Kitchen Order Display', onTap: () => context.push('/staff')), const SizedBox(height: 8)],

            // General Settings
            _ProfileTile(icon: Icons.language, title: 'language'.tr(), subtitle: context.locale.languageCode == 'en' ? 'English' : 'Myanmar', onTap: () => context.push('/profile/language')),
            const SizedBox(height: 8),
            _ProfileTile(icon: Icons.brightness_6, title: 'theme'.tr(), subtitle: 'Change app appearance', onTap: () => context.push('/profile/theme')),

            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                'sign_out'.tr(),
                style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
              ),
              onTap: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('sign_out'.tr()),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
