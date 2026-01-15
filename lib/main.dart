import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/repositories/auth_repository_impl.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/data/repositories/order_repository_impl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/usecases/auth/get_current_user_role_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/get_user_profile_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_in_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_out_usecase.dart';
import 'package:urban_cafe/domain/usecases/get_category_by_name.dart';
import 'package:urban_cafe/domain/usecases/get_favorite_items.dart';
import 'package:urban_cafe/domain/usecases/get_favorites.dart';
import 'package:urban_cafe/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/domain/usecases/get_sub_categories.dart';
import 'package:urban_cafe/domain/usecases/orders/create_order.dart';
import 'package:urban_cafe/domain/usecases/orders/get_admin_analytics.dart';
import 'package:urban_cafe/domain/usecases/orders/get_orders.dart';
import 'package:urban_cafe/domain/usecases/orders/update_order_status.dart';
import 'package:urban_cafe/domain/usecases/toggle_favorite.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/presentation/providers/category_manager_provider.dart';
import 'package:urban_cafe/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/presentation/providers/order_provider.dart';
import 'package:urban_cafe/presentation/providers/theme_provider.dart';
import 'package:urban_cafe/presentation/screens/admin/analytics_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/category_manager_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/edit_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/list_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/login_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/orders_screen.dart';
import 'package:urban_cafe/presentation/screens/cart_screen.dart';
import 'package:urban_cafe/presentation/screens/client_orders_screen.dart';
import 'package:urban_cafe/presentation/screens/login_screen.dart';
import 'package:urban_cafe/presentation/screens/main_menu_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_detail_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_screen.dart';
import 'package:urban_cafe/presentation/screens/profile/favorites_screen.dart';
import 'package:urban_cafe/presentation/screens/profile/language_screen.dart';
import 'package:urban_cafe/presentation/screens/profile/profile_screen.dart';
import 'package:urban_cafe/presentation/screens/profile/theme_screen.dart';
import 'package:urban_cafe/presentation/screens/staff/staff_orders_screen.dart';
import 'package:urban_cafe/presentation/widgets/main_scaffold.dart';
import 'package:urban_cafe/presentation/widgets/upgrade_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  await SupabaseClientProvider.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // Core Dependencies
  final authRepository = AuthRepositoryImpl(supabaseClient: SupabaseClientProvider.client);

  // UseCases
  final signInUseCase = SignInUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final getCurrentUserRoleUseCase = GetCurrentUserRoleUseCase(authRepository);
  final getUserProfileUseCase = GetUserProfileUseCase(authRepository);
  final signInWithGoogleUseCase = SignInWithGoogleUseCase(authRepository);

  final menuRepository = MenuRepositoryImpl();
  final getMainCategoriesUseCase = GetMainCategories(menuRepository);
  final getSubCategoriesUseCase = GetSubCategories(menuRepository);
  final getMenuItemsUseCase = GetMenuItems(menuRepository);
  final getCategoryByNameUseCase = GetCategoryByName(menuRepository);
  final getFavoritesUseCase = GetFavorites(menuRepository);
  final getFavoriteItemsUseCase = GetFavoriteItems(menuRepository);
  final toggleFavoriteUseCase = ToggleFavorite(menuRepository);

  final orderRepository = OrderRepositoryImpl();
  final getOrdersUseCase = GetOrders(orderRepository);
  final updateOrderStatusUseCase = UpdateOrderStatus(orderRepository);
  final createOrderUseCase = CreateOrder(orderRepository);
  final getAdminAnalyticsUseCase = GetAdminAnalytics(orderRepository);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('my')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(signInUseCase: signInUseCase, signOutUseCase: signOutUseCase, getCurrentUserRoleUseCase: getCurrentUserRoleUseCase, getUserProfileUseCase: getUserProfileUseCase, signInWithGoogleUseCase: signInWithGoogleUseCase),
          ),
          ChangeNotifierProvider(create: (_) => CartProvider(createOrderUseCase: createOrderUseCase)),
          ChangeNotifierProvider(
            create: (_) => MenuProvider(getMainCategoriesUseCase: getMainCategoriesUseCase, getSubCategoriesUseCase: getSubCategoriesUseCase, getMenuItemsUseCase: getMenuItemsUseCase, getCategoryByNameUseCase: getCategoryByNameUseCase, getFavoritesUseCase: getFavoritesUseCase, getFavoriteItemsUseCase: getFavoriteItemsUseCase, toggleFavoriteUseCase: toggleFavoriteUseCase),
          ),
          ChangeNotifierProvider(
            create: (_) => CategoryManagerProvider(getMainCategoriesUseCase: getMainCategoriesUseCase, getSubCategoriesUseCase: getSubCategoriesUseCase),
          ),
          ChangeNotifierProvider(create: (_) => AdminProvider(getAdminAnalyticsUseCase: getAdminAnalyticsUseCase)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => OrderProvider(getOrdersUseCase: getOrdersUseCase, updateOrderStatusUseCase: updateOrderStatusUseCase),
          ),
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
    final authProvider = context.read<AuthProvider>();

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
        GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),

        // SHELL ROUTE FOR BOTTOM NAV
        ShellRoute(
          builder: (context, state, child) {
            // Only show MainScaffold if NOT on login pages
            // Actually, ShellRoute wraps routes inside it.
            // Login pages are OUTSIDE ShellRoute.
            return MainScaffold(child: child);
          },
          routes: [
            // CLIENT ROUTES
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const MainMenuScreen(), transitionsBuilder: (context, animation, secondaryAnimation, child) => child),
            ),
            GoRoute(
              path: '/menu',
              builder: (context, state) => MenuScreen(initialMainCategory: state.uri.queryParameters['initialMainCategory']),
            ),
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
            GoRoute(path: '/orders', builder: (context, state) => const ClientOrdersScreen()),

            // STAFF ROUTES
            GoRoute(path: '/staff', builder: (context, state) => const StaffOrdersScreen()),

            // ADMIN ROUTES
            GoRoute(path: '/admin', builder: (context, state) => const AdminListScreen()),
            GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersScreen()),
            GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoryManagerScreen()),
            GoRoute(path: '/admin/analytics', builder: (context, state) => const AdminAnalyticsScreen()),

            // SHARED ROUTES
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'language', builder: (context, state) => const LanguageScreen()),
                GoRoute(path: 'theme', builder: (context, state) => const ThemeScreen()),
                GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                // For order history, we can either reuse /orders or make it a sub-route.
                // Reusing /orders is cleaner for deep linking, but we linked to /profile/orders in the profile screen.
                // Let's add it here as a sub-route for better context handling if needed,
                // OR we can just redirect/push to /orders.
                // In ProfileScreen I used context.push('/profile/orders'). So I must define it.
                // But reusing ClientOrdersScreen is fine.
                GoRoute(path: 'orders', builder: (context, state) => const ClientOrdersScreen()),
              ],
            ),
          ],
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
