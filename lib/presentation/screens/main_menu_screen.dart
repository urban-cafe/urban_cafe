import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/screens/menu_screen.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Widget _bigButton(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onPrimary));
          },
        ),
      ),
    );
  }

  Widget _logoHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.00), borderRadius: BorderRadius.circular(24)),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/logos/urbancafelogo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.local_cafe, size: 80, color: cs.primary),
            ),
          ),
        ),
        // const SizedBox(height: 12),
        // Text('Urban Cafe', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceBright,
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin',
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isConfigured) {
                Navigator.pushNamed(context, '/admin/login');
                return;
              }
              if (auth.isLoggedIn) {
                Navigator.pushNamed(context, '/admin');
              } else {
                Navigator.pushNamed(context, '/admin/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              _logoHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bigButton(context, 'HOT DRINKS', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen(initialMainCategory: 'HOT DRINKS')))),
                    const SizedBox(height: 16),
                    _bigButton(context, 'COLD DRINKS', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen(initialMainCategory: 'COLD DRINKS')))),
                    const SizedBox(height: 16),
                    _bigButton(context, 'FOOD', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen(initialMainCategory: 'FOOD')))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
