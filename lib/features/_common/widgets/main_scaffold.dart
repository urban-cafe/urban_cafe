import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';

/// InheritedWidget to share scroll controller with child screens
class ScrollControllerScope extends InheritedWidget {
  final ScrollController scrollController;
  final VoidCallback? onScrollUp;
  final VoidCallback? onScrollDown;

  const ScrollControllerScope({super.key, required this.scrollController, this.onScrollUp, this.onScrollDown, required super.child});

  static ScrollControllerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScrollControllerScope>();
  }

  @override
  bool updateShouldNotify(ScrollControllerScope oldWidget) => scrollController != oldWidget.scrollController;
}

class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final ScrollController _scrollController = ScrollController();
  bool _isNavVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;
    final delta = currentPosition - _lastScrollPosition;

    // Only trigger hide/show after 10px threshold
    if (delta.abs() > 10) {
      if (delta > 0 && _isNavVisible) {
        // Scrolling down → hide
        setState(() => _isNavVisible = false);
      } else if (delta < 0 && !_isNavVisible) {
        // Scrolling up → show
        setState(() => _isNavVisible = true);
      }
      _lastScrollPosition = currentPosition;
    }

    // Always show at top
    if (currentPosition <= 0 && !_isNavVisible) {
      setState(() => _isNavVisible = true);
    }
  }

  void _showNav() {
    if (!_isNavVisible) setState(() => _isNavVisible = true);
  }

  void _hideNav() {
    if (_isNavVisible) setState(() => _isNavVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final sizeClass = Responsive.windowSizeClass(context);
    final destinations = _buildDestinations(auth, cart);

    return ScrollControllerScope(
      scrollController: _scrollController,
      onScrollUp: _showNav,
      onScrollDown: _hideNav,
      child: Scaffold(
        extendBody: true,
        body: Row(
          children: [
            // NavigationRail for medium/expanded screens
            if (sizeClass != WindowSizeClass.compact)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: NavigationRail(
                  extended: sizeClass == WindowSizeClass.expanded,
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex),
                  destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon ?? d.icon, label: Text(d.label))).toList(),
                  labelType: sizeClass == WindowSizeClass.expanded ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                ),
              ),

            // Main content
            Expanded(child: widget.navigationShell),
          ],
        ),

        // Bottom NavigationBar for compact screens - with animated height
        bottomNavigationBar: sizeClass == WindowSizeClass.compact
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: _isNavVisible ? null : 0,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: NavigationBar(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex),
                  destinations: destinations,
                ),
              )
            : null,
      ),
    );
  }

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
    return [NavigationDestination(icon: const Icon(Icons.home), label: 'home'.tr())];
  }
}
