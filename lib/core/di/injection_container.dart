import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/services/cache_service.dart';
import 'package:urban_cafe/core/services/menu_cache_database.dart';
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
import 'package:urban_cafe/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/generate_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/process_point_transaction.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';
import 'package:urban_cafe/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_category_by_name.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_main_categories.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_menu_items.dart';
import 'package:urban_cafe/features/menu/domain/usecases/get_sub_categories.dart';
import 'package:urban_cafe/features/menu/presentation/providers/category_manager_provider.dart';
import 'package:urban_cafe/features/menu/presentation/providers/menu_provider.dart';

final GetIt sl = GetIt.instance;

/// Configure all dependencies
/// Call this in main() before runApp()
Future<void> configureDependencies(SupabaseClient client) async {
  // ─────────────────────────────────────────────────────────────────
  // 1. CORE & EXTERNAL
  // ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => client);
  sl.registerLazySingleton<CacheService>(() => CacheService());
  sl.registerLazySingleton<StorageService>(() => StorageService());
  sl.registerLazySingleton<MenuCacheDatabase>(() => MenuCacheDatabase());

  // ─────────────────────────────────────────────────────────────────
  // 2. AUTH FEATURE
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
    ),
  );

  // ─────────────────────────────────────────────────────────────────
  // 3. MENU FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl(sl(), sl<MenuCacheDatabase>()));

  // UseCases
  sl.registerLazySingleton(() => GetMainCategories(sl()));
  sl.registerLazySingleton(() => GetSubCategories(sl()));
  sl.registerLazySingleton(() => GetMenuItems(sl()));
  sl.registerLazySingleton(() => GetCategoryByName(sl()));

  // Providers
  sl.registerFactory(() => MenuProvider(getMainCategoriesUseCase: sl(), getSubCategoriesUseCase: sl(), getMenuItemsUseCase: sl(), getCategoryByNameUseCase: sl()));
  sl.registerFactory(() => CategoryManagerProvider(getMainCategoriesUseCase: sl(), getSubCategoriesUseCase: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 4. ADMIN FEATURE
  // ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => AdminProvider(storageService: sl()));

  // ─────────────────────────────────────────────────────────────────
  // 5. LOYALTY FEATURE
  // ─────────────────────────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<LoyaltyRepository>(() => LoyaltyRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => GeneratePointToken(sl()));
  sl.registerLazySingleton(() => ProcessPointTransaction(sl()));

  // Provider
  sl.registerFactory(() => LoyaltyProvider(generatePointToken: sl(), processPointTransaction: sl()));
}
