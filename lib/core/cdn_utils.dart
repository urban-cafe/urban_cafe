import 'package:urban_cafe/core/env.dart';

/// Rewrites Supabase Storage URLs to go through the Cloudflare CDN Worker.
///
/// On the first request, the Worker fetches from Supabase and caches the image
/// at Cloudflare's edge (globally). Every subsequent request is served directly
/// from the nearest Cloudflare edge node — Supabase Storage egress is only
/// consumed once per image per edge location.
///
/// Usage:
///   CachedNetworkImage(imageUrl: CdnUtils.storageUrl(item.imageUrl))
abstract final class CdnUtils {
  /// Rewrites a Supabase Storage URL to use the CDN worker.
  ///
  /// Returns the original URL unchanged if:
  ///  - [url] is null or empty
  ///  - The CDN worker URL is not configured (falls back gracefully)
  ///  - We're on web with no CDN configured (still works, just no CDN caching)
  static String? storageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final cdnBase = Env.cdnUrl;
    if (cdnBase.isEmpty) return url; // fallback: use Supabase URL directly

    try {
      final uri = Uri.parse(url);
      // Only rewrite Supabase storage URLs
      if (!uri.host.contains('supabase.co')) return url;

      // Replace host with CDN worker, keep path + query unchanged
      final cdnUri = Uri.parse(cdnBase);
      return uri.replace(scheme: cdnUri.scheme, host: cdnUri.host, port: cdnUri.hasPort ? cdnUri.port : null).toString();
    } catch (_) {
      return url; // never crash on a bad URL
    }
  }

  /// Menu image URL optimised for the given [displayWidth] (in logical pixels).
  ///
  /// Routing:
  ///   Supabase → Cloudflare Worker (edge cache, 1-year TTL)
  ///
  /// Note: Width is doubled for high-DPI (2× is enough for most screens).
  static String? menuImageUrl(String? url, {int displayWidth = 300}) {
    return storageUrl(url);
    // When you upgrade to Supabase Pro, replace with:
    // return _transformUrl(storageUrl(url), width: displayWidth * 2, quality: 75);
  }
}
