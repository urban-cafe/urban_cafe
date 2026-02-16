import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/services/cache_service.dart';
import 'package:urban_cafe/core/services/storage_service.dart';
import 'package:urban_cafe/features/admin/presentation/providers/admin_provider.dart';
import 'package:urban_cafe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:urban_cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_current_user_role_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
import 'package:urban_cafe/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/generate_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/get_point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/redeem_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/update_point_settings.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';
import 'package:urban_cafe/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_category_by_name.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_favorite_items.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_favorites.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_sub_categories.dart';
import 'package:urban_cafe/features/menu/domain/usecases/toggle_favorite.dart';
import 'package:urban_cafe/features/menu/presentation/providers/category_manager_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';
import 'package:urban_cafe/features/orders/data/repositories/order_repository_impl.dart';
import 'package:urban_cafe/features/orders/domain/repositories/order_repository.dart';
import 'package:urban_cafe/features/orders/domain/usecases/create_order.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_admin_analytics.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_orders.dart';
import 'package:urban_cafe/features/orders/domain/usecases/update_order_status.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';
import 'package:urban_cafe/features/pos/data/datasources/menu_local_datasource.dart';
import 'package:urban_cafe/features/pos/data/datasources/pos_local_datasource.dart';
import 'package:urban_cafe/features/pos/data/repositories/pos_repository_impl.dart';
import 'package:urban_cafe/features/pos/data/services/menu_sync_service.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';
import 'package:urban_cafe/features/pos/domain/usecases/create_pos_order.dart';
import 'package:urban_cafe/features/pos/domain/usecases/get_pos_orders.dart';
import 'package:urban_cafe/features/pos/domain/usecases/sync_pos_orders.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';

final GetIt sl = GetIt.instance;

/// Configure all dependencies
/// Call this in main() before runApp()
Future<void> configureDependencies(SupabaseClient client) async {
  // ─────────────────────────────────────────────────────────────────
  // 1. CORE & EXTERNAL
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => client);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<CacheService>(() => CacheService());
  sl.registerLazySingleton<StorageService>(() => StorageService());

  // ─────────────────────────────────────────────────────────────────
  // 2. DATA SOURCES & SERVICES (POS/Offline)
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => PosLocalDatasource());
  sl.registerLazySingleton(() => MenuLocalDatasource());
  sl.registerLazySingleton(() => MenuSyncService(supabaseClient: sl(), menuLocalDatasource: sl(), posLocalDatasource: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 3. AUTH FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(supabaseClient: sl()));

  // UseCases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserRoleUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignInAnonymouslyUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  // Provider
  sl.registerFactory(
    () => AuthProvider(
      signInUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserRoleUseCase: sl(),
      getUserProfileUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signUpUseCase: sl(),
      signInAnonymouslyUseCase: sl(),
      updateProfileUseCase: sl(),
      menuSyncService: sl(),
    ),
  );

  // ─────────────────────────────────────────────────────────────────
  // 4. MENU FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => GetMainCategories(sl()));
  sl.registerLazySingleton(() => GetSubCategories(sl()));
  sl.registerLazySingleton(() => GetMenuItems(sl()));
  sl.registerLazySingleton(() => GetCategoryByName(sl()));
  sl.registerLazySingleton(() => GetFavorites(sl()));
  sl.registerLazySingleton(() => GetFavoriteItems(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));

  // Providers
  sl.registerFactory(
    () => MenuProvider(
      getMainCategoriesUseCase: sl(),
      getSubCategoriesUseCase: sl(),
      getMenuItemsUseCase: sl(),
      getCategoryByNameUseCase: sl(),
      getFavoritesUseCase: sl(),
      getFavoriteItemsUseCase: sl(),
      toggleFavoriteUseCase: sl(),
    ),
  );
  sl.registerFactory(() => CategoryManagerProvider(getMainCategoriesUseCase: sl(), getSubCategoriesUseCase: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 5. ORDERS FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => GetOrders(sl()));
  sl.registerLazySingleton(() => UpdateOrderStatus(sl()));
  sl.registerLazySingleton(() => CreateOrder(sl()));
  sl.registerLazySingleton(() => GetAdminAnalytics(sl()));

  // Provider
  sl.registerFactory(() => OrderProvider(getOrdersUseCase: sl(), updateOrderStatusUseCase: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 6. CART & ADMIN
  // ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => CartProvider(createOrderUseCase: sl()));

  sl.registerFactory(() => AdminProvider(getAdminAnalyticsUseCase: sl(), storageService: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 7. LOYALTY FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<LoyaltyRepository>(() => LoyaltyRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => GeneratePointToken(sl()));
  sl.registerLazySingleton(() => RedeemPointToken(sl()));
  sl.registerLazySingleton(() => GetPointSettings(sl()));
  sl.registerLazySingleton(() => UpdatePointSettings(sl()));

  // Provider
  sl.registerFactory(() => LoyaltyProvider(generatePointToken: sl(), redeemPointToken: sl(), getPointSettings: sl(), updatePointSettings: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 8. POS FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<PosRepository>(() => PosRepositoryImpl(sl(), sl(), sl()));

  // UseCases
  sl.registerLazySingleton(() => CreatePosOrder(sl()));
  sl.registerLazySingleton(() => GetPosOrders(sl()));
  sl.registerLazySingleton(() => SyncPosOrders(sl()));

  // Provider
  sl.registerFactory(() => PosProvider(createPosOrderUseCase: sl(), getPosOrdersUseCase: sl(), syncPosOrdersUseCase: sl(), repository: sl(), connectivity: sl()));
}
