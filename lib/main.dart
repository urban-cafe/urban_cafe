import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
// DI
import 'package:urban_cafe/core/di/injection_container.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/routing/app_router.dart';
import 'package:urban_cafe/core/services/supabase_client.dart';
import 'package:urban_cafe/core/theme.dart';
// Providers
import 'package:urban_cafe/features/_common/theme_provider.dart';
import 'package:urban_cafe/features/_common/widgets/upgrade_listener.dart';
import 'package:urban_cafe/features/admin/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/category_manager_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';

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
          ChangeNotifierProvider(create: (_) => sl<LoyaltyProvider>()),
          ChangeNotifierProvider(create: (_) => sl<PosProvider>()),
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
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Create router ONCE — it reacts to auth changes via refreshListenable.
    _appRouter = AppRouter(authProvider: context.read<AuthProvider>(), navigatorKey: _rootNavigatorKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/logos/urbancafelogo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
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
          routerConfig: _appRouter.router,
          builder: (context, child) => UpgradeListener(navigatorKey: _rootNavigatorKey, child: child!),
        );
      },
    );
  }
}
