import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';

class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // ─── Branch index mapping ────────────────────────────────────────
  // Shell branches are registered in this order:
  //   0: Home (client)  1: QR  2: Profile
  //   3: Admin           4: Admin Categories  5: QR Scanner
  //
  // Each role maps its nav bar indices → shell branch indices.

  static const _clientBranchIndices = [0, 1, 2]; // Home, QR, Profile
  static const _guestBranchIndices = [0, 2]; // Home, Profile
  static const _adminBranchIndices = [3, 4, 5, 2]; // Admin, Categories, QRScanner, Profile
  static const _staffBranchIndices = [5, 2]; // QRScanner, Profile

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
    final sizeClass = Responsive.windowSizeClass(context);
    final destinations = _buildDestinations(auth);
    final selectedIndex = _navIndexFromBranch(auth);

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail for medium/expanded screens
          if (sizeClass != WindowSizeClass.compact)
            NavigationRail(
              extended: sizeClass == WindowSizeClass.expanded,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onNavTapped(index, auth),
              destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon ?? d.icon, label: Text(d.label))).toList(),
              labelType: sizeClass == WindowSizeClass.expanded ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
            ),

          // Main content
          Expanded(child: widget.navigationShell),
        ],
      ),

      // Bottom NavigationBar for compact screens
      bottomNavigationBar: sizeClass == WindowSizeClass.compact
          ? NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(size: 22, color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onNavTapped(index, auth),
                destinations: destinations,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            )
          : null,
    );
  }

  List<NavigationDestination> _buildDestinations(AuthProvider auth) {
    if (auth.isGuest) {
      return [NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()), NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr())];
    } else if (auth.isClient) {
      return [
        NavigationDestination(icon: const Icon(Icons.restaurant_menu), label: 'menu'.tr()),
        NavigationDestination(icon: const Icon(Icons.qr_code_rounded), label: 'qr_code'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    } else if (auth.isStaff) {
      return [NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: 'qr_scan'.tr()), NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr())];
    } else if (auth.isAdmin) {
      return [
        NavigationDestination(icon: const Icon(Icons.dashboard), label: 'items'.tr()),
        NavigationDestination(icon: const Icon(Icons.category), label: 'categories'.tr()),
        NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: 'qr_scan'.tr()),
        NavigationDestination(icon: const Icon(Icons.person), label: 'profile'.tr()),
      ];
    }
    return [NavigationDestination(icon: const Icon(Icons.home), label: 'home'.tr())];
  }
}
