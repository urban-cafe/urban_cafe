import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';

class SupabaseClientProvider {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;

  static Future<void> initialize({required String url, required String anonKey}) async {
    if (!Env.isConfigured) {
      // Provide a dummy client to satisfy GetIt dependency injection
      // when running without a .env configuration. Repositories already
      // check Env.isConfigured to return early failures.
      _client = SupabaseClient('https://dummy.supabase.co', 'dummy_key');
      return;
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }
}
