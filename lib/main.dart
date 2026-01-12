import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';
import 'package:urban_cafe/presentation/screens/admin/category_manager_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/edit_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/list_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/login_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/orders_screen.dart';
import 'package:urban_cafe/presentation/screens/login_screen.dart';
import 'package:urban_cafe/presentation/screens/main_menu_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_detail_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_screen.dart';
import 'package:urban_cafe/presentation/screens/cart_screen.dart';
import 'package:urban_cafe/presentation/widgets/upgrade_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  await SupabaseClientProvider.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const UrbanCafeApp(),
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
    final authProvider = context.read<AuthProvider>();

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isAdmin = authProvider.isAdmin;
        final isStaff = authProvider.isStaff;
        final location = state.uri.toString();

        final isGoingToLogin = location == '/login';
        final isGoingToAdminLogin = location == '/admin/login';
        final isGoingToAdminArea = location.startsWith('/admin');
        final isGoingToOrders = location == '/admin/orders';

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
          // If trying to go to login page, redirect based on role
          if (isGoingToLogin || isGoingToAdminLogin) {
            if (isAdmin) return '/admin';
            if (isStaff) return '/admin/orders';
            return '/'; // Client goes home
          }

          // Role-based Access Control for Admin Area
          if (isGoingToAdminArea) {
            // STAFF: Can only access /admin/orders
            if (isStaff) {
              if (!isGoingToOrders) {
                return '/admin/orders';
              }
            }
            // CLIENT: Cannot access admin area
            else if (!isAdmin && !isStaff) {
              return '/';
            }
            // ADMIN: Can access everything (no redirect needed)
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        // Keep the main menu alive and avoid rebuilds on back navigation.
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const MainMenuScreen(), transitionDuration: const Duration(milliseconds: 0), reverseTransitionDuration: const Duration(milliseconds: 0), transitionsBuilder: (context, animation, secondaryAnimation, child) => child, maintainState: true),
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) => MenuScreen(initialMainCategory: state.uri.queryParameters['initialMainCategory']),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
        GoRoute(path: '/admin', builder: (context, state) => const AdminListScreen()),
        GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersScreen()),
        GoRoute(
          path: '/admin/edit',
          builder: (context, state) {
            // FIX: Allow null here because 'item' is optional for creating new items
            final item = state.extra as MenuItemEntity?;

            return AdminEditScreen(
              id: state.uri.queryParameters['id'],
              item: item, // Pass the nullable item
            );
          },
        ),
        GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoryManagerScreen()),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            // FIX: Check if extra is null before casting
            final item = state.extra as MenuItemEntity?;

            // If item is null (e.g. browser refresh), handle it gracefully.
            // For example, redirect back to menu or show an error screen.
            if (item == null) {
              return const Scaffold(body: Center(child: Text("Item not found. Please go back.")));
            }

            return MenuDetailScreen(item: item);
          },
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'UrbanCafe',
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
