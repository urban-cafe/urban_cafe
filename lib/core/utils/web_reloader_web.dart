import 'package:web/web.dart' as web;

void reloadWebPage() {
  // `reload()` may serve the stale cached bundle.
  // Setting location.href with a unique timestamp forces a full
  // network fetch, bypassing service-worker and browser caches.
  final origin = web.window.location.origin;
  final path = web.window.location.pathname;
  final bust = DateTime.now().millisecondsSinceEpoch;
  web.window.location.href = '$origin$path?v=$bust';
}
