import 'package:flutter/foundation.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/domain/entities/user_role.dart';
import 'package:urban_cafe/domain/usecases/auth/get_current_user_role_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_in_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/domain/usecases/auth/sign_out_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserRoleUseCase getCurrentUserRoleUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;

  bool loading = false;
  String? error;
  UserRole? _role;

  bool get isConfigured => Env.isConfigured;
  bool get isLoggedIn => Env.isConfigured && SupabaseClientProvider.client.auth.currentUser != null;
  String? get currentUserEmail => SupabaseClientProvider.client.auth.currentUser?.email;

  UserRole get role => _role ?? UserRole.client;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isClient => role == UserRole.client;

  AuthProvider({
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserRoleUseCase,
    required this.signInWithGoogleUseCase,
  }) {
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (!isLoggedIn) {
      _role = null;
      return;
    }

    final result = await getCurrentUserRoleUseCase(NoParams());
    result.fold(
      (failure) {
        debugPrint('Error loading user role: ${failure.message}');
        _role = UserRole.client;
      },
      (role) {
        _role = role;
        notifyListeners();
      },
    );
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
      (role) {
        _role = role;
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
    notifyListeners();
  }
}
