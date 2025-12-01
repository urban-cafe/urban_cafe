import 'package:flutter/foundation.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  bool loading = false;
  String? error;
  bool get isConfigured => Env.isConfigured;
  bool get isLoggedIn => Env.isConfigured && SupabaseClientProvider.client.auth.currentUser != null;

  Future<bool> signIn(String email, String password) async {
    if (!Env.isConfigured) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await SupabaseClientProvider.client.auth.signInWithPassword(email: email, password: password);
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
    notifyListeners();
  }
}
