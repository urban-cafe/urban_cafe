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
  static const qr = '/qr';
  static const loyaltyHistory = '/loyalty-history';

  // Profile
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileLanguage = '/profile/language';
  static const profileTheme = '/profile/theme';

  // Admin
  static const admin = '/admin';
  static const adminCategories = '/admin/categories';
  static const adminEdit = '/admin/edit';
  static const adminLoyaltyHistory = '/admin/loyalty-history';

  // QR Scanner (staff/admin)
  static const qrScanner = '/qr-scanner';

  // Full-screen (no bottom nav)
  static const detail = '/detail';
}
