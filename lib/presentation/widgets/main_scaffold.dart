import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final location = GoRouterState.of(context).uri.toString();

    // Determine current index based on location
    int currentIndex = _calculateSelectedIndex(location, auth);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context, auth),
        destinations: _buildDestinations(auth, cart),
      ),
    );
  }

  int _calculateSelectedIndex(String location, AuthProvider auth) {
    if (auth.isClient) {
      if (location == '/' || location.startsWith('/menu')) return 0;
      if (location.startsWith('/cart')) return 1;
      if (location.startsWith('/orders')) return 2;
      if (location.startsWith('/profile')) return 3;
    } else if (auth.isStaff) {
      if (location.startsWith('/staff')) return 0;
      if (location.startsWith('/admin/orders')) return 1; // Staff can view order list
      if (location.startsWith('/profile')) return 2;
    } else if (auth.isAdmin) {
      if (location == '/admin') return 0; // Dashboard
      if (location.startsWith('/admin/orders')) return 1;
      if (location.startsWith('/admin/categories')) return 2;
      if (location.startsWith('/profile')) return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, AuthProvider auth) {
    if (auth.isClient) {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/cart'); break;
        case 2: context.go('/orders'); break;
        case 3: context.go('/profile'); break;
      }
    } else if (auth.isStaff) {
      switch (index) {
        case 0: context.go('/staff'); break;
        case 1: context.go('/admin/orders'); break;
        case 2: context.go('/profile'); break;
      }
    } else if (auth.isAdmin) {
      switch (index) {
        case 0: context.go('/admin'); break;
        case 1: context.go('/admin/orders'); break;
        case 2: context.go('/admin/categories'); break;
        case 3: context.go('/profile'); break;
      }
    }
  }

  List<NavigationDestination> _buildDestinations(AuthProvider auth, CartProvider cart) {
    if (auth.isClient) {
      return [
        NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_cart),
          ), 
          label: 'cart'.tr()
        ),
        NavigationDestination(icon: const Icon(Icons.receipt_long), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isStaff) {
      return [
        NavigationDestination(icon: const Icon(Icons.kitchen), label: 'kitchen'.tr()),
        NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isAdmin) {
      return [
        NavigationDestination(icon: const Icon(Icons.dashboard), label: 'items'.tr()),
        NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.category), label: 'categories'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    }
    // Default fallback (should be login)
    return [NavigationDestination(icon: const Icon(Icons.home), label: 'home'.tr())];
  }
}
