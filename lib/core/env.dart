import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    final v = dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null;
    return v ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String get supabaseAnonKey {
    final v = dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null;
    return v ?? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get webUrl {
    final v = dotenv.isInitialized ? dotenv.env['WEB_URL'] : null;
    return v ?? const String.fromEnvironment('WEB_URL', defaultValue: '');
  }

  /// Cloudflare Worker CDN URL for Supabase Storage images.
  /// e.g. https://urbancafe-cdn.your-account.workers.dev
  static String get cdnUrl {
    final v = dotenv.isInitialized ? dotenv.env['CDN_URL'] : null;
    return v ?? const String.fromEnvironment('CDN_URL', defaultValue: '');
  }

  static const String storageBucket = 'menu-images';
}
