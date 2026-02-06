import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/services/cache_service.dart';
import 'package:urban_cafe/core/services/storage_service.dart';
// Cart & Admin Features
import 'package:urban_cafe/features/admin/presentation/providers/admin_provider.dart';
// Auth Feature
import 'package:urban_cafe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:urban_cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_current_user_role_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/cart/presentation/providers/cart_provider.dart';
// Menu Feature
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
// Orders Feature
import 'package:urban_cafe/features/orders/data/repositories/order_repository_impl.dart';
import 'package:urban_cafe/features/orders/domain/repositories/order_repository.dart';
import 'package:urban_cafe/features/orders/domain/usecases/create_order.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_admin_analytics.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_orders.dart';
import 'package:urban_cafe/features/orders/domain/usecases/update_order_status.dart';
import 'package:urban_cafe/features/orders/presentation/providers/order_provider.dart';

final GetIt sl = GetIt.instance;

/// Configure all dependencies
/// Call this in main() before runApp()
Future<void> configureDependencies(SupabaseClient client) async {
  // ─────────────────────────────────────────────────────────────────
  // CORE SERVICES
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => client);
  sl.registerLazySingleton<CacheService>(() => CacheService());
  sl.registerLazySingleton<StorageService>(() => StorageService());

  // ─────────────────────────────────────────────────────────────────
  // REPOSITORIES
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(supabaseClient: sl<SupabaseClient>()));

  sl.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl(sl<SupabaseClient>()));

  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl<SupabaseClient>()));

  // ─────────────────────────────────────────────────────────────────
  // AUTH USECASES
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserRoleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl<AuthRepository>()));

  // ─────────────────────────────────────────────────────────────────
  // MENU USECASES
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetMainCategories(sl<MenuRepository>()));
  sl.registerLazySingleton(() => GetSubCategories(sl<MenuRepository>()));
  sl.registerLazySingleton(() => GetMenuItems(sl<MenuRepository>()));
  sl.registerLazySingleton(() => GetCategoryByName(sl<MenuRepository>()));
  sl.registerLazySingleton(() => GetFavorites(sl<MenuRepository>()));
  sl.registerLazySingleton(() => GetFavoriteItems(sl<MenuRepository>()));
  sl.registerLazySingleton(() => ToggleFavorite(sl<MenuRepository>()));

  // ─────────────────────────────────────────────────────────────────
  // ORDER USECASES
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetOrders(sl<OrderRepository>()));
  sl.registerLazySingleton(() => UpdateOrderStatus(sl<OrderRepository>()));
  sl.registerLazySingleton(() => CreateOrder(sl<OrderRepository>()));
  sl.registerLazySingleton(() => GetAdminAnalytics(sl<OrderRepository>()));

  // ─────────────────────────────────────────────────────────────────
  // PROVIDERS (Factory - new instance each time)
  // ─────────────────────────────────────────────────────────────────
  sl.registerFactory<AuthProvider>(() => AuthProvider(signInUseCase: sl(), signOutUseCase: sl(), getCurrentUserRoleUseCase: sl(), getUserProfileUseCase: sl(), signInWithGoogleUseCase: sl()));

  sl.registerFactory<MenuProvider>(
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

  sl.registerFactory<CategoryManagerProvider>(() => CategoryManagerProvider(getMainCategoriesUseCase: sl(), getSubCategoriesUseCase: sl()));

  sl.registerFactory<CartProvider>(() => CartProvider(createOrderUseCase: sl()));

  sl.registerFactory<OrderProvider>(() => OrderProvider(getOrdersUseCase: sl(), updateOrderStatusUseCase: sl()));

  sl.registerFactory<AdminProvider>(() => AdminProvider(getAdminAnalyticsUseCase: sl(), storageService: sl()));
}
