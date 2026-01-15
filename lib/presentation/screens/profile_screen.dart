import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:urban_cafe/domain/entities/order_entity.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/order_provider.dart';
import 'package:urban_cafe/presentation/widgets/theme_selection_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch orders if client to show history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isClient) {
        context.read<OrderProvider>().fetchOrders();
      }
    });
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
      appBar: AppBar(title: Text('profile'.tr()), actions: const [ThemeSelectionButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... (Profile Header)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initial,
                      style: theme.textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Language Switcher
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SegmentedButton<Locale>(
                segments: const [
                  ButtonSegment(value: Locale('en'), label: Text('English')),
                  ButtonSegment(value: Locale('my'), label: Text('Myanmar')),
                ],
                selected: {context.locale},
                onSelectionChanged: (Set<Locale> newSelection) {
                  context.setLocale(newSelection.first);
                },
              ),
            ),

            const SizedBox(height: 16),

            // 2. ROLE SPECIFIC SECTIONS
            if (auth.isClient) _buildClientSection(context),
            if (auth.isStaff) _buildStaffSection(context),
            if (auth.isAdmin) _buildAdminSection(context),

            const SizedBox(height: 32),

            // 3. ACCOUNT ACTIONS
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text('sign_out'.tr(), style: TextStyle(color: colorScheme.error)),
              onTap: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('recent_orders'.tr(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => context.push('/orders'), child: Text('view_all'.tr())),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<OrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.orders.isEmpty) {
              return Skeletonizer(
                enabled: true,
                child: Column(children: List.generate(2, (i) => const Card(child: SizedBox(height: 80)))),
              );
            }

            if (provider.orders.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("No recent orders")),
                ),
              );
            }

            // Show top 3 recent orders
            final recent = provider.orders.take(3).toList();
            return Column(children: recent.map((order) => _MiniOrderCard(order: order)).toList());
          },
        ),
      ],
    );
  }

  Widget _buildStaffSection(BuildContext context) {
    return Column(
      children: [
        _ActionCard(icon: Icons.kitchen, title: 'kitchen_display'.tr(), subtitle: 'Manage active orders', color: Colors.orange, onTap: () => context.push('/staff')),
        const SizedBox(height: 16),
        _ActionCard(icon: Icons.receipt_long, title: 'order_list'.tr(), subtitle: 'View all orders', color: Colors.blue, onTap: () => context.push('/admin/orders')),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      children: [
        _ActionCard(icon: Icons.dashboard, title: 'admin_dashboard'.tr(), subtitle: 'Manage items and categories', color: Colors.purple, onTap: () => context.push('/admin')),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.people,
          title: 'user_management'.tr(),
          subtitle: 'Manage staff and clients',
          color: Colors.teal,
          onTap: () {}, // Placeholder
        ),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.settings,
          title: 'system_settings'.tr(),
          subtitle: 'Configure app settings',
          color: Colors.grey,
          onTap: () {}, // Placeholder
        ),
      ],
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniOrderCard extends StatelessWidget {
  final OrderEntity order;
  const _MiniOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        onTap: () {
          // Could navigate to detail
        },
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.receipt, color: cs.onPrimaryContainer, size: 20),
        ),
        title: Text('${order.items.length} items • \$${order.totalAmount.toStringAsFixed(0)}'),
        subtitle: Text(timeago.format(order.createdAt)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Text(
            order.status.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
