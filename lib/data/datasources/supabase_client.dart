import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env.dart';

class SupabaseClientProvider {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;

  static Future<void> initialize({required String url, required String anonKey}) async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }
}
