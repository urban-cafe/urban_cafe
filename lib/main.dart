import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// DI
import 'package:urban_cafe/core/di/injection_container.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/services/supabase_client.dart';
import 'package:urban_cafe/core/theme.dart';
// Common/Shared
import 'package:urban_cafe/features/_common/theme_provider.dart';
import 'package:urban_cafe/features/_common/widgets/main_scaffold.dart';
import 'package:urban_cafe/features/_common/widgets/upgrade_listener.dart';
// Admin Feature
import 'package:urban_cafe/features/admin/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/features/admin/presentation/screens/analytics_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/category_manager_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/edit_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/list_screen.dart';
import 'package:urban_cafe/features/admin/presentation/screens/login_screen.dart' as admin;
import 'package:urban_cafe/features/admin/presentation/screens/orders_screen.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/auth/presentation/screens/login_screen.dart';
// Cart Feature
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/cart/presentation/screens/cart_screen.dart';
import 'package:urban_cafe/features/menu/domain/entities/menu_item.dart';
import 'package:urban_cafe/features/menu/presentation/providers/category_manager_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/features/menu/presentation/screens/main_menu_screen.dart';
import 'package:urban_cafe/features/menu/presentation/screens/menu_detail_screen.dart';
import 'package:urban_cafe/features/menu/presentation/screens/menu_screen.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';
import 'package:urban_cafe/features/orders/presentation/screens/client_orders_screen.dart';
import 'package:urban_cafe/features/orders/presentation/screens/staff/staff_orders_screen.dart';
// Profile Feature
import 'package:urban_cafe/features/profile/presentation/screens/favorites_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/language_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/profile_screen.dart';
import 'package:urban_cafe/features/profile/presentation/screens/theme_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  await SupabaseClientProvider.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // Configure all dependencies with get_it
  await configureDependencies(SupabaseClientProvider.client);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('my')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
          ChangeNotifierProvider(create: (_) => sl<CartProvider>()),
          ChangeNotifierProvider(create: (_) => sl<MenuProvider>()),
          ChangeNotifierProvider(create: (_) => sl<CategoryManagerProvider>()),
          ChangeNotifierProvider(create: (_) => sl<AdminProvider>()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => sl<OrderProvider>()),
        ],
        child: const UrbanCafeApp(),
      ),
    ),
  );
}

class UrbanCafeApp extends StatefulWidget {
  const UrbanCafeApp({super.key});

  @override
  State<UrbanCafeApp> createState() => _UrbanCafeAppState();
}

class _UrbanCafeAppState extends State<UrbanCafeApp> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/logos/urbancafelogo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider to rebuild router when role/login changes
    final authProvider = context.watch<AuthProvider>();

    // Define branches based on role
    List<StatefulShellBranch> branches;

    if (authProvider.isAdmin) {
      branches = [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminListScreen(),
              routes: [GoRoute(path: 'analytics', builder: (context, state) => const AdminAnalyticsScreen())],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoryManagerScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
                GoRoute(path: 'theme', builder: (context, state) => const ThemeScreen()),
                GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                GoRoute(path: 'orders', builder: (context, state) => const ClientOrdersScreen()),
              ],
            ),
          ],
        ),
      ];
    } else if (authProvider.isStaff) {
      branches = [
        StatefulShellBranch(
          routes: [GoRoute(path: '/staff', builder: (context, state) => const StaffOrdersScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
                GoRoute(path: 'theme', builder: (context, state) => const ThemeScreen()),
                GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                GoRoute(path: 'orders', builder: (context, state) => const ClientOrdersScreen()),
              ],
            ),
          ],
        ),
      ];
    } else {
      // Client (Default)
      branches = [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const MainMenuScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => child),
              routes: [
                GoRoute(
                  path: 'menu', // /menu
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
        StatefulShellBranch(
          routes: [GoRoute(path: '/cart', builder: (context, state) => const CartScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/orders', builder: (context, state) => const ClientOrdersScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
                GoRoute(path: 'theme', builder: (context, state) => const ThemeScreen()),
                GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                GoRoute(path: 'orders', builder: (context, state) => const ClientOrdersScreen()),
              ],
            ),
          ],
        ),
      ];
    }

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider,
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isAdmin = authProvider.isAdmin;
        final isStaff = authProvider.isStaff;
        final location = state.uri.toString();

        final isGoingToLogin = location == '/login';
        final isGoingToAdminLogin = location == '/admin/login';
        final isGoingToAdminArea = location.startsWith('/admin') && !isGoingToAdminLogin;

        // 1. Not logged in
        if (!isLoggedIn) {
          // If not logged in and not on login page, redirect to login
          if (!isGoingToLogin && !isGoingToAdminLogin) {
            return '/login';
          }
          return null; // Stay on login page
        }

        // 2. Logged in
        if (isLoggedIn) {
          // Redirect root path '/' to role-specific home for non-clients
          if (location == '/') {
            if (isAdmin) return '/admin';
            if (isStaff) return '/staff';
          }

          // If trying to go to login page, redirect based on role
          if (isGoingToLogin || isGoingToAdminLogin) {
            if (isAdmin) return '/admin';
            if (isStaff) return '/staff'; // Staff goes to Kitchen Display
            return '/'; // Client goes home
          }

          // Role-based Access Control for Admin Area
          if (isGoingToAdminArea) {
            // STAFF: Can only access /admin/orders (Order Management)
            // Wait, Staff should primarily be in /staff.
            // If they try to go to full admin panel (/admin), redirect them?
            if (isStaff) {
              // Staff might need access to Order List (/admin/orders) too, as per previous code.
              // But they should NOT access /admin (Item List).
              if (location == '/admin') {
                return '/staff';
              }
            }
            // CLIENT: Cannot access admin area
            else if (!isAdmin && !isStaff) {
              return '/';
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/admin/login', builder: (context, state) => const admin.AdminLoginScreen()),

        // SHELL ROUTE FOR BOTTOM NAV
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            // Only show MainScaffold if NOT on login pages
            // Actually, ShellRoute wraps routes inside it.
            // Login pages are OUTSIDE ShellRoute.
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: branches,
        ),

        // FULL SCREEN ROUTES (No Bottom Nav)
        GoRoute(
          path: '/detail',
          parentNavigatorKey: _rootNavigatorKey, // Push on top of everything
          builder: (context, state) {
            final item = state.extra as MenuItemEntity?;
            if (item == null) return const Scaffold(body: Center(child: Text("Item not found")));
            return MenuDetailScreen(item: item);
          },
        ),
        GoRoute(
          path: '/admin/edit',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final item = state.extra as MenuItemEntity?;
            return AdminEditScreen(id: state.uri.queryParameters['id'], item: item);
          },
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'UrbanCafe',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          builder: (context, child) => UpgradeListener(navigatorKey: _rootNavigatorKey, child: child!),
        );
      },
    );
  }
}
