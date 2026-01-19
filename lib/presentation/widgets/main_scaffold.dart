import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: _buildDestinations(auth, cart),
      ),
    );
  }

  // Remove _calculateSelectedIndex and _onItemTapped as they are handled by navigationShell

  List<NavigationDestination> _buildDestinations(AuthProvider auth, CartProvider cart) {
    if (auth.isClient) {
      return [
        NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()),
        NavigationDestination(
          icon: Badge(isLabelVisible: cart.itemCount > 0, label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart)),
          label: 'cart'.tr(),
        ),
        NavigationDestination(icon: const Icon(Icons.receipt_long), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isStaff) {
      return [NavigationDestination(icon: const Icon(Icons.kitchen), label: 'kitchen'.tr()), NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()), NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr())];
    } else if (auth.isAdmin) {
      return [NavigationDestination(icon: const Icon(Icons.dashboard), label: 'items'.tr()), NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()), NavigationDestination(icon: const Icon(Icons.category), label: 'categories'.tr()), NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr())];
    }
    // Default fallback (should be login)
    return [NavigationDestination(icon: const Icon(Icons.home), label: 'home'.tr())];
  }
}
