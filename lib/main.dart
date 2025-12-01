import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(title: 'UrbanCafe', theme: AppTheme.theme, debugShowCheckedModeBanner: false, routes: {'/': (_) => const MainMenuScreen(), '/menu': (_) => const MenuScreen(), '/admin/login': (_) => const AdminLoginScreen(), '/admin': (_) => const AdminListScreen()}),
    );
  }
}
