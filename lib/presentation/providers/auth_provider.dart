import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/domain/entities/user_profile.dart';
import 'package:urban_cafe/domain/entities/user_role.dart';

class AuthProvider extends ChangeNotifier {
  bool loading = false;
  String? error;
  UserRole? _role;

  bool get isConfigured => Env.isConfigured;
  bool get isLoggedIn => Env.isConfigured && SupabaseClientProvider.client.auth.currentUser != null;

  UserRole get role => _role ?? UserRole.client;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isClient => role == UserRole.client;

  AuthProvider() {
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (!isLoggedIn) {
      _role = null;
      return;
    }

    try {
      final userId = SupabaseClientProvider.client.auth.currentUser!.id;
      final response = await SupabaseClientProvider.client.from('profiles').select().eq('id', userId).single();

      final profile = UserProfile.fromJson(response);
      _role = profile.role;
      notifyListeners();
    } catch (e) {
      // If profile fetch fails (e.g. table doesn't exist yet or network error), default to client
      debugPrint('Error loading user role: $e');
      _role = UserRole.client;
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await SupabaseClientProvider.client.auth.signInWithPassword(email: email, password: password);
      await _loadUserRole();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      // For Web, this redirects to Google.
      // For Mobile, it opens a browser/system sheet if configured with deep links.
      // Since we don't have deep links fully configured in code yet (AndroidManifest/Info.plist),
      // this is primarily optimized for Web or simple mobile browser flows.
      await SupabaseClientProvider.client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: kIsWeb ? null : 'io.supabase.urbancafe://login-callback/');

      // Note: On Web, the page will reload after redirect, so _loadUserRole() might happen on app init.
      // On Mobile, we need to listen to auth state changes.

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!Env.isConfigured) return;
    await SupabaseClientProvider.client.auth.signOut();
    _role = null;
    notifyListeners();
  }
}
