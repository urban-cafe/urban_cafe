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

  // ─── Branch index mapping ────────────────────────────────────────
  // Shell branches are registered in this order:
  //   0: Home (client)  1: Cart  2: QR  3: Orders  4: Profile
  //   5: Admin           6: Admin Orders    7: Admin Categories
  //   8: QR Scanner (admin/staff)
  //   9: Staff
  //
  // Each role maps its nav bar indices → shell branch indices.

  static const _clientBranchIndices = [0, 1, 2, 3, 4]; // Home, Cart, QR, Orders, Profile
  static const _guestBranchIndices = [0, 4]; // Home, Profile (guests can't access cart/orders/QR)
  static const _adminBranchIndices = [5, 6, 7, 8, 4]; // Admin, AdminOrders, AdminCategories, QRScanner, Profile
  static const _staffBranchIndices = [9, 6, 8, 4]; // Staff, AdminOrders, QRScanner, Profile

  List<int> _branchIndices(AuthProvider auth) {
    if (auth.isAdmin) return _adminBranchIndices;
    if (auth.isStaff) return _staffBranchIndices;
    if (auth.isGuest) return _guestBranchIndices;
    return _clientBranchIndices;
  }

  /// Convert shell branch index → nav bar index for the current role.
  int _navIndexFromBranch(AuthProvider auth) {
    final indices = _branchIndices(auth);
    final shellIndex = widget.navigationShell.currentIndex;
    final navIndex = indices.indexOf(shellIndex);
    return navIndex >= 0 ? navIndex : 0;
  }

  /// Convert nav bar index → shell branch index.
  void _onNavTapped(int navIndex, AuthProvider auth) {
    final indices = _branchIndices(auth);
    final shellIndex = indices[navIndex];
    widget.navigationShell.goBranch(shellIndex, initialLocation: shellIndex == widget.navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final sizeClass = Responsive.windowSizeClass(context);
    final destinations = _buildDestinations(auth, cart);
    final selectedIndex = _navIndexFromBranch(auth);

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
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _onNavTapped(index, auth),
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
                child: NavigationBar(selectedIndex: selectedIndex, onDestinationSelected: (index) => _onNavTapped(index, auth), destinations: destinations),
              )
            : null,
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(AuthProvider auth, CartProvider cart) {
    if (auth.isGuest) {
      return [NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()), NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr())];
    } else if (auth.isClient) {
      return [
        NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()),
        NavigationDestination(
          icon: Badge(isLabelVisible: cart.itemCount > 0, label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart)),
          label: 'cart'.tr(),
        ),
        NavigationDestination(icon: const Icon(Icons.qr_code_rounded), label: 'qr_code'.tr()),
        NavigationDestination(icon: const Icon(Icons.receipt_long), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isStaff) {
      return [
        NavigationDestination(icon: const Icon(Icons.kitchen), label: 'kitchen'.tr()),
        NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: 'qr_scan'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isAdmin) {
      return [
        NavigationDestination(icon: const Icon(Icons.dashboard), label: 'items'.tr()),
        NavigationDestination(icon: const Icon(Icons.list_alt), label: 'orders'.tr()),
        NavigationDestination(icon: const Icon(Icons.category), label: 'categories'.tr()),
        NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: 'qr_scan'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    }
    return [NavigationDestination(icon: const Icon(Icons.home), label: 'home'.tr())];
  }
}
