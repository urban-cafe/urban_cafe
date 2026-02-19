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
import 'package:urban_cafe/features/pos/data/services/menu_sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserRoleUseCase getCurrentUserRoleUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignUpUseCase signUpUseCase;
  final SignInAnonymouslyUseCase signInAnonymouslyUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final MenuSyncService? menuSyncService;

  bool loading = false;
  bool _refreshingProfile = false;
  bool get refreshingProfile => _refreshingProfile;
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
    this.menuSyncService,
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
            _cancelOAuthTimeout(); // Cancel timeout if OAuth completed successfully
            _loadUserRole();
            break;

          case AuthChangeEvent.signedOut:
            _role = null;
            _profile = null;
            loading = false;
            error = null;
            _cancelOAuthTimeout(); // Cancel timeout on sign out
            notifyListeners();
            break;

          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('[AuthProvider] Auth state error: $error');
        _cancelOAuthTimeout(); // Cancel timeout on error
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _oauthTimeout?.cancel();
    super.dispose();
  }

  // ─── Error Message Mapping ────────────────────────────────────

  /// Converts technical error messages to user-friendly ones
  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('invalid login credentials') || lowerError.contains('invalid email or password')) {
      return 'Email or password is incorrect. Please try again.';
    }

    if (lowerError.contains('user not found') || lowerError.contains('no user found')) {
      return 'No account found with this email address.';
    }

    if (lowerError.contains('email already') || lowerError.contains('already registered')) {
      return 'An account with this email already exists.';
    }

    if (lowerError.contains('weak password') || lowerError.contains('password should be at least')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Connection failed. Please check your internet and try again.';
    }

    if (lowerError.contains('email not confirmed') || lowerError.contains('email_confirmation_required')) {
      return 'Please check your email and confirm your account first.';
    }

    // Return original message if no mapping found
    return technicalError;
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

    // Auto-download menu data for staff/admin
    if (isAdmin || isStaff) {
      _triggerMenuSync();
    }
  }

  /// Trigger background menu data download.
  void _triggerMenuSync() {
    final sync = menuSyncService;
    if (sync == null) return;
    sync.init().then((_) {
      if (!sync.isSyncing) {
        sync.downloadAllMenuData();
      }
    });
  }

  Future<void> refreshUser() async {
    if (_refreshingProfile) return; // Guard against double-tap
    _refreshingProfile = true;
    notifyListeners();
    try {
      await _loadUserRole();
    } finally {
      _refreshingProfile = false;
      notifyListeners();
    }
  }

  // ─── Email/Password Sign In ───────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await signInUseCase(SignInParams(email: email, password: password));

      return result.fold(
        (failure) {
          error = _getUserFriendlyError(failure.message);
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
    } catch (e) {
      error = 'An unexpected error occurred. Please try again.';
      loading = false;
      notifyListeners();
      debugPrint('[AuthProvider] Sign in error: $e');
      return false;
    }
  }

  // ─── Email/Password Sign Up ───────────────────────────────────

  Future<bool> signUp(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await signUpUseCase(SignUpParams(email: email, password: password));

      return result.fold(
        (failure) {
          error = _getUserFriendlyError(failure.message);
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
    } catch (e) {
      error = 'An unexpected error occurred. Please try again.';
      loading = false;
      notifyListeners();
      debugPrint('[AuthProvider] Sign up error: $e');
      return false;
    }
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

    try {
      final result = await signInWithGoogleUseCase(NoParams());

      return await result.fold(
        (failure) {
          error = _getUserFriendlyError(failure.message);
          loading = false;
          notifyListeners();
          return false;
        },
        (launched) async {
          if (!launched) {
            error = 'Failed to open browser for sign in.';
            loading = false;
            notifyListeners();
            return false;
          }

          // Browser launched successfully. Set a timeout to reset loading state
          // if the user cancels or doesn't complete the OAuth flow.
          _startOAuthTimeout();
          return true;
        },
      );
    } catch (e) {
      error = 'An unexpected error occurred. Please try again.';
      loading = false;
      notifyListeners();
      debugPrint('[AuthProvider] Google sign in error: $e');
      return false;
    }
  }

  Timer? _oauthTimeout;

  void _startOAuthTimeout() {
    _oauthTimeout?.cancel();
    // Reset loading after 60 seconds if no auth state change occurs
    _oauthTimeout = Timer(const Duration(seconds: 60), () {
      if (loading && !isLoggedIn) {
        loading = false;
        error = 'Sign in was cancelled or timed out.';
        notifyListeners();
        debugPrint('[AuthProvider] OAuth timeout - resetting loading state');
      }
    });
  }

  void _cancelOAuthTimeout() {
    _oauthTimeout?.cancel();
    _oauthTimeout = null;
  }

  // ─── Anonymous (Guest) Sign In ────────────────────────────────

  Future<bool> signInAsGuest() async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await signInAnonymouslyUseCase(NoParams());

      return result.fold(
        (failure) {
          error = _getUserFriendlyError(failure.message);
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
    } catch (e) {
      error = 'An unexpected error occurred. Please try again.';
      loading = false;
      notifyListeners();
      debugPrint('[AuthProvider] Guest sign in error: $e');
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────

  Future<void> signOut() async {
    if (!Env.isConfigured) return;

    // Clear local data before signing out
    try {
      await menuSyncService?.clearAllLocalData();
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }

    await signOutUseCase(NoParams());
    _role = null;
    _profile = null;
    notifyListeners();
  }

  // ─── Update Profile ───────────────────────────────────────────

  Future<bool> updateProfile({String? fullName, String? phoneNumber, String? address}) async {
    if (!Env.isConfigured) return false;
    if (_profile == null) return false;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final updatedProfile = _profile!.copyWith(fullName: fullName, phoneNumber: phoneNumber, address: address);
      final result = await updateProfileUseCase(updatedProfile);

      return result.fold(
        (failure) {
          error = _getUserFriendlyError(failure.message);
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
    } catch (e) {
      error = 'Failed to update profile. Please try again.';
      loading = false;
      notifyListeners();
      debugPrint('[AuthProvider] Update profile error: $e');
      return false;
    }
  }
}
