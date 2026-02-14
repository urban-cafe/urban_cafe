/// Centralized route path constants to eliminate magic strings.
abstract final class AppRoutes {
  // Auth
  static const login = '/login';
  static const signUp = '/signup';
  static const emailConfirmation = '/auth/callback';
  static const adminLogin = '/admin/login';

  // Client
  static const home = '/';
  static const menu = '/menu';
  static const cart = '/cart';
  static const qr = '/qr';
  static const orders = '/orders';

  // Profile
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileLanguage = '/profile/language';
  static const profileTheme = '/profile/theme';
  static const profileFavorites = '/profile/favorites';
  static const profileOrders = '/profile/orders';

  // Admin
  static const admin = '/admin';
  static const adminAnalytics = '/admin/analytics';
  static const adminOrders = '/admin/orders';
  static const adminCategories = '/admin/categories';
  static const adminEdit = '/admin/edit';
  static const adminPointSettings = '/admin/point-settings';

  // QR Scanner (staff/admin)
  static const qrScanner = '/qr-scanner';

  // Staff
  static const staff = '/staff';

  // Full-screen (no bottom nav)
  static const detail = '/detail';
}
