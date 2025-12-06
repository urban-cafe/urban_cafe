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

class UrbanCafeApp extends StatelessWidget {
  const UrbanCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
        GoRoute(
          path: '/menu',
          builder: (context, state) => MenuScreen(initialMainCategory: state.uri.queryParameters['initialMainCategory']),
        ),
        GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
        GoRoute(path: '/admin', builder: (context, state) => const AdminListScreen()),
        GoRoute(
          path: '/detail',
          builder: (context, state) => MenuDetailScreen(item: state.extra as MenuItemEntity),
        ),
        GoRoute(
          path: '/admin/edit',
          builder: (context, state) => AdminEditScreen(id: state.uri.queryParameters['id'], item: state.extra as MenuItemEntity?),
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
