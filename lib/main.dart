import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/presentation/screens/admin/edit_screen.dart';
import 'package:urban_cafe/presentation/screens/menu_detail_screen.dart';
import 'core/theme.dart';
import 'package:go_router/go_router.dart';
import 'domain/entities/menu_item.dart';
import 'core/env.dart';
import 'data/datasources/supabase_client.dart';
import 'presentation/screens/menu_screen.dart';
import 'presentation/screens/main_menu_screen.dart';
import 'presentation/screens/admin/login_screen.dart';
import 'presentation/providers/menu_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/admin/list_screen.dart';

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

class UrbanCafeApp extends StatelessWidget {
  const UrbanCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MainMenuScreen()),
        GoRoute(
          path: '/menu',
          builder: (ctx, state) => MenuScreen(initialMainCategory: state.uri.queryParameters['initialMainCategory']),
        ),
        GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminListScreen()),
        GoRoute(
          path: '/detail',
          builder: (ctx, state) => MenuDetailScreen(item: state.extra as MenuItemEntity),
        ),
        GoRoute(
          path: '/admin/edit',
          builder: (ctx, state) => AdminEditScreen(id: state.uri.queryParameters['id'], item: state.extra as MenuItemEntity?),
        ),
      ],
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp.router(title: 'UrbanCafe', theme: AppTheme.theme, darkTheme: AppTheme.darkTheme, themeMode: ThemeMode.system, debugShowCheckedModeBanner: false, routerConfig: router),
    );
  }
}
