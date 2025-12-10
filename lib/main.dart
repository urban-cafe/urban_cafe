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
import 'package:urban_cafe/presentation/providers/theme_provider.dart';
import 'package:urban_cafe/presentation/screens/admin/category_manager_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/edit_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/list_screen.dart';
import 'package:urban_cafe/presentation/screens/admin/login_screen.dart';
import 'package:urban_cafe/presentation/screens/main_menu_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_detail_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  await SupabaseClientProvider.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const UrbanCafeApp());
}

class UrbanCafeApp extends StatefulWidget {
  const UrbanCafeApp({super.key});

  @override
  State<UrbanCafeApp> createState() => _UrbanCafeAppState();
}

class _UrbanCafeAppState extends State<UrbanCafeApp> {
  // Precache the image when the app starts
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/logos/urbancafelogo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        // Keep the main menu alive and avoid rebuilds on back navigation.
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(key: state.pageKey, child: const MainMenuScreen(), transitionDuration: const Duration(milliseconds: 0), reverseTransitionDuration: const Duration(milliseconds: 0), transitionsBuilder: (context, animation, secondaryAnimation, child) => child, maintainState: true),
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) => MenuScreen(initialMainCategory: state.uri.queryParameters['initialMainCategory']),
        ),
        GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
        GoRoute(path: '/admin', builder: (context, state) => const AdminListScreen()),
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
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(title: 'UrbanCafe', theme: AppTheme.theme, darkTheme: AppTheme.darkTheme, themeMode: themeProvider.themeMode, debugShowCheckedModeBanner: false, routerConfig: router);
        },
      ),
    );
  }
}
