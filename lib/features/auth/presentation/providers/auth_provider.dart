import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/services/supabase_client.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_current_user_role_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:urban_cafe/features/auth/domain/usecases/update_profile_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserRoleUseCase getCurrentUserRoleUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignUpUseCase signUpUseCase;
  final SignInAnonymouslyUseCase signInAnonymouslyUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  bool loading = false;
  String? error;
  UserRole? _role;
  UserProfile? _profile;

  StreamSubscription<AuthState>? _authSubscription;

  bool get isConfigured => Env.isConfigured;
  bool get isLoggedIn => Env.isConfigured && SupabaseClientProvider.client.auth.currentUser != null;
  String? get currentUserEmail => SupabaseClientProvider.client.auth.currentUser?.email;
  User? get currentUser => SupabaseClientProvider.client.auth.currentUser;

  /// True when the current user is an anonymous (guest) user.
  bool get isGuest {
    final user = currentUser;
    if (user == null) return false;
    return user.isAnonymous;
  }

  UserRole get role => _role ?? UserRole.client;
  UserProfile? get profile => _profile;
  int get loyaltyPoints => _profile?.loyaltyPoints ?? 0;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isClient => role == UserRole.client;

  AuthProvider({
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserRoleUseCase,
    required this.getUserProfileUseCase,
    required this.signInWithGoogleUseCase,
    required this.signUpUseCase,
    required this.signInAnonymouslyUseCase,
    required this.updateProfileUseCase,
  }) {
    _loadUserRole();
    _listenToAuthStateChanges();
  }

  // ─── Reactive auth state listener ──────────────────────────────

  /// Listens to Supabase auth state changes (OAuth callbacks, token refresh,
  /// sign-out from another tab, etc.) and updates app state reactively.
  void _listenToAuthStateChanges() {
    _authSubscription = SupabaseClientProvider.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugPrint('[AuthProvider] onAuthStateChange: $event');

        switch (event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
            // User signed in (including OAuth callback) or token refreshed
            _loadUserRole();
            break;

          case AuthChangeEvent.signedOut:
            _role = null;
            _profile = null;
            loading = false;
            error = null;
            notifyListeners();
            break;

          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('[AuthProvider] Auth state error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ─── Profile loading ──────────────────────────────────────────

  Future<void> _loadUserRole() async {
    if (!isLoggedIn) {
      _role = null;
      _profile = null;
      return;
    }

    // Guest users don't have profiles — default to client role
    if (isGuest) {
      _role = UserRole.client;
      _profile = null;
      notifyListeners();
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
      },
    );
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadUserRole();
  }

  // ─── Email/Password Sign In ───────────────────────────────────

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

  // ─── Email/Password Sign Up ───────────────────────────────────

  Future<bool> signUp(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    final result = await signUpUseCase(SignUpParams(email: email, password: password));

    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (role) async {
        _role = role;
        await _loadUserRole();
        loading = false;
        notifyListeners();
        return true;
      },
    );
  }

  // ─── Google OAuth Sign In ─────────────────────────────────────

  /// Initiates Google OAuth flow. The browser opens for authentication.
  /// State updates happen reactively via [_listenToAuthStateChanges]
  /// when the deep link callback returns the user to the app.
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
      (launched) {
        // `launched` only means the browser was opened successfully.
        // Actual sign-in state is handled by onAuthStateChange.
        // Keep loading true until the callback fires.
        return launched;
      },
    );
  }

  // ─── Anonymous (Guest) Sign In ────────────────────────────────

  Future<bool> signInAsGuest() async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    final result = await signInAnonymouslyUseCase(NoParams());

    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (role) {
        _role = role;
        _profile = null;
        loading = false;
        notifyListeners();
        return true;
      },
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────────

  Future<void> signOut() async {
    if (!Env.isConfigured) return;
    await signOutUseCase(NoParams());
    _role = null;
    _profile = null; // Clear profile data
    notifyListeners();
  }

  // ─── Update Profile ───────────────────────────────────────────

  Future<bool> updateProfile({String? fullName}) async {
    if (!Env.isConfigured) return false;
    if (_profile == null) return false;

    loading = true;
    error = null;
    notifyListeners();

    final updatedProfile = _profile!.copyWith(fullName: fullName);
    final result = await updateProfileUseCase(updatedProfile);

    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (profile) {
        _profile = profile;
        loading = false;
        notifyListeners();
        return true;
      },
    );
  }
}
