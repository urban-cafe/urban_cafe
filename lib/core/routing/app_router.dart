import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_cafe/core/routing/routes.dart';
import 'package:urban_cafe/features/_common/widgets/main_scaffold.dart';
// Feature screens
import 'package:urban_cafe/features/admin/presentation/screens/category_manager_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/edit_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/list_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/login_screen.dart' as admin;
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:urban_cafe/features/auth/presentation/screens/login_screen.dart';
import 'package:urban_cafe/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:urban_cafe/features/loyalty/presentation/screens/admin_loyalty_history_screen.dart';
import 'package:urban_cafe/features/loyalty/presentation/screens/client_loyalty_history_screen.dart';
import 'package:urban_cafe/features/loyalty/presentation/screens/qr_display_screen.dart';
import 'package:urban_cafe/features/loyalty/presentation/screens/qr_scan_landing_screen.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/screens/main_menu_screen.dart';
import 'package:urban_cafe/features/menu/presentation/screens/menu_detail_screen.dart';
import 'package:urban_cafe/features/menu/presentation/screens/menu_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/contact_us_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/edit_profile_screen.dart';

import 'package:urban_cafe/features/profile/presentation/screens/language_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/profile_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/theme_screen.dart';

/// Builds the [GoRouter] for the app.
///
/// All role branches are registered at once so they are always available.
/// Access control is handled entirely by the [_redirect] logic.
class AppRouter {
  AppRouter({required AuthProvider authProvider, required GlobalKey<NavigatorState> navigatorKey}) : _authProvider = authProvider, _navigatorKey = navigatorKey;

  final AuthProvider _authProvider;
  final GlobalKey<NavigatorState> _navigatorKey;

  late final GoRouter router = GoRouter(
    navigatorKey: _navigatorKey,
    refreshListenable: _authProvider,
    initialLocation: AppRoutes.home,
    redirect: _redirect,
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const _SplashGate(), transitionsBuilder: (context, animation, secondaryAnimation, child) => child),
      ),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.signUp, builder: (context, state) => const SignUpScreen()),
      GoRoute(path: AppRoutes.emailConfirmation, builder: (context, state) => const EmailConfirmationScreen()),
      GoRoute(path: AppRoutes.adminLogin, builder: (context, state) => const admin.AdminLoginScreen()),

      // Shell route with ALL branches — redirect controls which ones are accessible
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // ── Client branches (index 0-2) ─────────────────────
          // 0: Home/Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const MainMenuScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => child),
                routes: [
                  GoRoute(
                    path: 'menu',
                    builder: (context, state) => MenuScreen(
                      initialMainCategory: state.uri.queryParameters['initialMainCategory'],
                      filter: state.uri.queryParameters['filter'],
                      focusSearch: state.uri.queryParameters['focusSearch'] == 'true',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 1: QR (loyalty)
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.qr, builder: (context, state) => const QrDisplayScreen()),
              GoRoute(path: AppRoutes.loyaltyHistory, builder: (context, state) => const ClientLoyaltyHistoryScreen()),
            ],
          ),
          // 2: Profile (shared across all roles)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
                  GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
                  GoRoute(path: 'theme', builder: (context, state) => const ThemeScreen()),

                  GoRoute(path: 'contact', builder: (context, state) => const ContactUsScreen()),
                ],
              ),
            ],
          ),
          // ── Admin branches (index 3-5) ──────────────────────
          // 3: Admin dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                builder: (context, state) => const AdminListScreen(),
                routes: [GoRoute(path: 'loyalty-history', builder: (context, state) => const AdminLoyaltyHistoryScreen())],
              ),
            ],
          ),
          // 4: Admin categories
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.adminCategories, builder: (context, state) => const AdminCategoryManagerScreen())],
          ),
          // 5: QR Scanner (admin/staff)
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.qrScanner, builder: (context, state) => const QrScanLandingScreen())],
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppRoutes.detail,
        parentNavigatorKey: _navigatorKey,
        builder: (context, state) {
          final item = state.extra as MenuItemEntity?;
          if (item == null) {
            return const Scaffold(body: Center(child: Text("Item not found")));
          }
          return MenuDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: AppRoutes.adminEdit,
        parentNavigatorKey: _navigatorKey,
        builder: (context, state) {
          final item = state.extra as MenuItemEntity?;
          return AdminEditScreen(id: state.uri.queryParameters['id'], item: item);
        },
      ),
    ],
  );

  // ─── Redirect logic ──────────────────────────────────────────────

  /// Routes that guests are allowed to access (browse-only).
  static const _guestAllowedPrefixes = [
    AppRoutes.home,
    AppRoutes.menu, // Guests can browse full menu
    AppRoutes.detail,
    AppRoutes.profile, // Guests need profile for settings and sign out
  ];

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.toString();

    // 0. While still loading the user role, hold on splash
    if (_authProvider.initializing) {
      if (location != '/splash') return '/splash';
      return null;
    }

    // Once initialized, redirect splash to the right place
    if (location == '/splash') {
      if (!_authProvider.isLoggedIn) return AppRoutes.login;
      if (_authProvider.isAdmin) return AppRoutes.admin;
      if (_authProvider.isStaff) return AppRoutes.qrScanner;
      return AppRoutes.home;
    }

    final isLoggedIn = _authProvider.isLoggedIn;
    final isGuest = _authProvider.isGuest;
    final isAdmin = _authProvider.isAdmin;
    final isStaff = _authProvider.isStaff;

    final isGoingToLogin = location == AppRoutes.login;
    final isGoingToSignUp = location == AppRoutes.signUp;
    final isGoingToAdminLogin = location == AppRoutes.adminLogin;
    final isGoingToAdminArea = location.startsWith('/admin') && !isGoingToAdminLogin;

    // 1. Not logged in → redirect to login (unless already on auth pages)
    if (!isLoggedIn) {
      if (!isGoingToLogin && !isGoingToAdminLogin && !isGoingToSignUp) return AppRoutes.login;
      return null;
    }

    // 2. Guest users can only browse — restrict to allowed routes
    if (isGuest) {
      final isAllowed = _guestAllowedPrefixes.any((prefix) => location == prefix || location.startsWith('$prefix/') || location.startsWith('$prefix?'));

      if (isGoingToLogin || isGoingToSignUp) {
        return null;
      }

      if (!isAllowed) {
        return AppRoutes.home;
      }
      return null;
    }

    // 3. Logged in → redirect root to role-specific home
    if (location == AppRoutes.home) {
      if (isAdmin) return AppRoutes.admin;
      if (isStaff) return AppRoutes.qrScanner; // Staff land on QR scanner
    }

    // 4. Logged in but going to auth pages → redirect based on role
    if (isGoingToLogin || isGoingToAdminLogin || isGoingToSignUp) {
      if (isAdmin) return AppRoutes.admin;
      if (isStaff) return AppRoutes.qrScanner;
      return AppRoutes.home;
    }

    // 5. Role-based access control for admin area
    if (isGoingToAdminArea) {
      if (isStaff && location == AppRoutes.admin) return AppRoutes.qrScanner;
      if (!isAdmin && !isStaff) return AppRoutes.home;
    }

    return null;
  }
}

/// Lightweight splash screen shown while [AuthProvider] resolves the user role.
/// Prevents the wrong navigation tabs from flashing on cold start.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logos/urbancafelogo.png', width: 120, height: 120),
            const SizedBox(height: 32),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}
