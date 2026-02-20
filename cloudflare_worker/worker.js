/**
 * UrbanCafe – Supabase Storage CDN Proxy
 *
 * Sits between the Flutter app and Supabase Storage.
 * Every image request is:
 *   1. Served from Cloudflare's edge cache if already cached (no Supabase hit)
 *   2. Fetched from Supabase, cached at the edge, then returned (first request only)
 *
 * Result: Supabase only sees the FIRST request per image per edge node.
 * All subsequent requests worldwide are served from Cloudflare for free.
 */

// Cache TTL constants
const IMAGE_CACHE_TTL = 60 * 60 * 24 * 365; // 1 year (menu images rarely change)
const ERROR_CACHE_TTL = 60;                   // 1 minute (don't cache errors long)
const ALLOWED_ORIGIN_PATTERN = /^https:\/\/(.+\.)?urbancafe\.pages\.dev$/;

export default {
  async fetch(request, env, ctx) {
    // ── CORS Preflight (OPTIONS) ──────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // ── Security: only GET / HEAD ─────────────────────────────────────────────
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    const url = new URL(request.url);

    // ── Security: only proxy /storage/** paths ────────────────────────────────
    if (!url.pathname.startsWith('/storage/')) {
      return new Response('Not Found', { status: 404 });
    }

    // ── 1. Check Cloudflare edge cache ────────────────────────────────────────
    const cache = caches.default;
    const cacheKey = new Request(url.toString());

    const cached = await cache.match(cacheKey);
    if (cached) {
      return addCorsHeaders(cached, request, env);
    }

    // ── 2. Cache miss → fetch from Supabase ───────────────────────────────────
    const supabaseUrl = `${env.SUPABASE_URL}${url.pathname}${url.search}`;

    let upstream;
    try {
      upstream = await fetch(supabaseUrl, {
        method: request.method,
        headers: { 'apikey': env.SUPABASE_ANON_KEY },
        // Tell Cloudflare to cache the upstream response internally
        cf: {
          cacheTtl: IMAGE_CACHE_TTL,
          cacheEverything: true,
        },
      });
    } catch (err) {
      return new Response('Failed to reach storage', { status: 502 });
    }

    // ── 3. Build cacheable response ───────────────────────────────────────────
    const isImage = isImageContentType(upstream.headers.get('content-type') ?? '');
    const ttl = upstream.ok && isImage ? IMAGE_CACHE_TTL : ERROR_CACHE_TTL;

    const responseHeaders = new Headers(upstream.headers);
    // Strip Supabase-specific headers that shouldn't leak
    responseHeaders.delete('x-kong-upstream-latency');
    responseHeaders.delete('x-kong-proxy-latency');
    responseHeaders.delete('via');

    // Strong cache headers — Cloudflare + browser
    if (upstream.ok) {
      responseHeaders.set('Cache-Control', `public, max-age=${ttl}, immutable`);
      responseHeaders.set('CDN-Cache-Control', `public, max-age=${ttl}`);
    } else {
      responseHeaders.set('Cache-Control', `public, max-age=${ERROR_CACHE_TTL}`);
    }
    responseHeaders.set('X-Served-By', 'urbancafe-cdn');

    const response = new Response(upstream.body, {
      status: upstream.status,
      headers: responseHeaders,
    });

    // Store in Cloudflare edge cache (non-blocking)
    if (upstream.ok) {
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return addCorsHeaders(response, request, env);
  },
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function isImageContentType(ct) {
  return ct.startsWith('image/') || ct.includes('octet-stream');
}

function addCorsHeaders(response, request, env) {
  const headers = new Headers(response.headers);

  // Wildcard CORS is safest for public images. It prevents any Vary: Origin
  // cache-key fragmentation and guarantees Flutter Web/CanvasKit can load it.
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');

  return new Response(response.body, {
    status: response.status,
    headers,
  });
}
