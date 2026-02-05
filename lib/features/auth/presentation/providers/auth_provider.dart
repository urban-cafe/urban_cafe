import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/services/supabase_client.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_current_user_role_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_out_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserRoleUseCase getCurrentUserRoleUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;

  bool loading = false;
  String? error;
  UserRole? _role;
  UserProfile? _profile;

  bool get isConfigured => Env.isConfigured;
  bool get isLoggedIn => Env.isConfigured && SupabaseClientProvider.client.auth.currentUser != null;
  String? get currentUserEmail => SupabaseClientProvider.client.auth.currentUser?.email;
  // Add getter for current user
  User? get currentUser => SupabaseClientProvider.client.auth.currentUser;

  UserRole get role => _role ?? UserRole.client;
  UserProfile? get profile => _profile;
  int get loyaltyPoints => _profile?.loyaltyPoints ?? 0;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isClient => role == UserRole.client;

  AuthProvider({required this.signInUseCase, required this.signOutUseCase, required this.getCurrentUserRoleUseCase, required this.getUserProfileUseCase, required this.signInWithGoogleUseCase}) {
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (!isLoggedIn) {
      _role = null;
      _profile = null;
      return;
    }

    // Load Profile
    final profileResult = await getUserProfileUseCase(NoParams());
    profileResult.fold(
      (failure) {
        debugPrint('Error loading user profile: ${failure.message}');
        _role = UserRole.client;
        _profile = null;
      },
      (profile) {
        _profile = profile;
        _role = profile.role;
        notifyListeners();
      },
    );
  }

  Future<void> refreshProfile() async {
    await _loadUserRole();
  }

  Future<bool> signIn(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    final result = await signInUseCase(SignInParams(email: email, password: password));

    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (role) async {
        _role = role;
        await _loadUserRole(); // Fetch full profile (points, name, etc.)
        loading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    final result = await signInWithGoogleUseCase(NoParams());

    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (success) {
        // After Google Sign In, we might need to fetch role separately if redirect happens immediately
        // But if we are here, we are back in the app.
        // We should trigger load role just in case.
        _loadUserRole();
        loading = false;
        notifyListeners();
        return success;
      },
    );
  }

  Future<void> signOut() async {
    if (!Env.isConfigured) return;
    await signOutUseCase(NoParams());
    _role = null;
    _profile = null; // Clear profile data
    notifyListeners();
  }
}
