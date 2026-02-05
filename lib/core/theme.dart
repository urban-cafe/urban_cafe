import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.success, required this.danger});
  final Color success;
  final Color danger;

  @override
  BrandColors copyWith({Color? success, Color? danger}) => BrandColors(
    success: success ?? this.success,
    danger: danger ?? this.danger,
  );

  @override
  ThemeExtension<BrandColors> lerp(
    ThemeExtension<BrandColors>? other,
    double t,
  ) {
    if (other is! BrandColors) return this;
    return BrandColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppTheme {
  // Material 3 Color Scheme for Urban Cafe
  // Primary Colors
  static const Color primary = Color(0xFF6D4C41);
  static const Color onPrimary = Color(0xFFFFFBF8);
  static const Color primaryContainer = Color(0xFFE8D5CC);
  static const Color onPrimaryContainer = Color(0xFF2C1810);

  // Secondary Colors
  static const Color secondary = Color(0xFF8D6E63);
  static const Color onSecondary = Color(0xFFFFFBF8);
  static const Color secondaryContainer = Color(0xFFEDE0D9);
  static const Color onSecondaryContainer = Color(0xFF3E2723);

  // Tertiary Colors
  static const Color tertiary = Color(0xFFA1887F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF0E4DE);
  static const Color onTertiaryContainer = Color(0xFF4E342E);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Background & Surface
  static const Color background = Color(0xFFFFFBF8);
  static const Color onBackground = Color(0xFF1C1B1B);
  static const Color surface = Color(0xFFFFFBF8);
  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color surfaceVariant = Color(0xFFF4DFD4);
  static const Color onSurfaceVariant = Color(0xFF52443D);

  // Outline
  static const Color outline = Color(0xFF85736B);
  static const Color outlineVariant = Color(0xFFD7C3B9);

  // Inverse
  static const Color inverseSurface = Color(0xFF312F2F);
  static const Color onInverseSurface = Color(0xFFF4F0EF);
  static const Color inversePrimary = Color(0xFFDEBBAD);

  // Surface Tones
  static const Color surfaceTint = Color(0xFF6D4C41);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Accents
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentRed = Color(0xFFC62828);

  // ---------------------------------------------------------------------------
  // GRADIENT HELPERS
  // ---------------------------------------------------------------------------
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, tertiary],
  );

  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
  );

  // ---------------------------------------------------------------------------
  // DYNAMIC FONT CONFIGURATION
  // ---------------------------------------------------------------------------
  static TextStyle _appFont(TextStyle? textStyle, {FontWeight? fontWeight}) {
    return GoogleFonts.openSans(textStyle: textStyle, fontWeight: fontWeight);
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _appFont(base.displayLarge, fontWeight: FontWeight.bold),
      displayMedium: _appFont(base.displayMedium, fontWeight: FontWeight.bold),
      displaySmall: _appFont(base.displaySmall, fontWeight: FontWeight.w600),
      headlineLarge: _appFont(base.headlineLarge, fontWeight: FontWeight.bold),
      headlineMedium: _appFont(
        base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: _appFont(base.headlineSmall, fontWeight: FontWeight.w600),
      titleLarge: _appFont(base.titleLarge, fontWeight: FontWeight.bold),
      titleMedium: _appFont(base.titleMedium, fontWeight: FontWeight.bold),
      titleSmall: _appFont(base.titleSmall, fontWeight: FontWeight.bold),
      bodyLarge: _appFont(base.bodyLarge),
      bodyMedium: _appFont(base.bodyMedium),
      bodySmall: _appFont(base.bodySmall),
      labelLarge: _appFont(base.labelLarge, fontWeight: FontWeight.bold),
    );
  }

  static ColorScheme get lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: shadow,
    scrim: scrim,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: inversePrimary,
  );

  static ThemeData get theme {
    final base = ThemeData.light();

    return base.copyWith(
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(base.textTheme).apply(
        displayColor: onSurface,
        bodyColor: onSurface,
        fontFamilyFallback: ['Roboto'],
      ),

      // Card Theme with premium shadows
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),

      // FilledButton Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _appFont(
            null,
            fontWeight: FontWeight.bold,
          ).copyWith(fontSize: 16),
          elevation: 0,
        ),
      ),

      // OutlinedButton Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: outlineVariant, width: 1.5),
          textStyle: _appFont(
            null,
            fontWeight: FontWeight.bold,
          ).copyWith(fontSize: 16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        disabledColor: surfaceVariant,
        labelStyle: _appFont(
          null,
          fontWeight: FontWeight.w600,
        ).copyWith(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide(color: outlineVariant.withValues(alpha: 0.5)),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _appFont(
          null,
          fontWeight: FontWeight.bold,
        ).copyWith(fontSize: 18, color: onSurface),
        iconTheme: const IconThemeData(color: onSurface),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),

      extensions: const [BrandColors(success: accentGreen, danger: accentRed)],
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    const darkBg = Color(0xFF1A1412); // Deeper coffee black
    const darkSurface = Color(0xFF241E1C); // Warm charcoal
    const darkCard = Color(0xFF2E2624); // Card background
    const darkPrimary = Color(0xFFD4A574); // Warm gold-brown
    const darkOnPrimary = Color(0xFF2C1810);
    const darkSecondary = Color(0xFFE7C4A5);
    const darkTertiary = Color(0xFFFBE4C8);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        secondary: darkSecondary,
        onSecondary: const Color(0xFF3E2723),
        tertiary: darkTertiary,
        onTertiary: const Color(0xFF3C2F04),
        surface: darkSurface,
        onSurface: const Color(0xFFF5EDE8),
        surfaceContainerHighest: darkCard,
        onSurfaceVariant: const Color(0xFFD7C3B9),
        outline: const Color(0xFF9C8579),
        outlineVariant: const Color(0xFF4A3F3A),
      ),
      scaffoldBackgroundColor: darkBg,

      // Card Theme for dark mode
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),

      // FilledButton for dark mode
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _appFont(
            null,
            fontWeight: FontWeight.bold,
          ).copyWith(fontSize: 16),
          elevation: 0,
        ),
      ),

      // OutlinedButton for dark mode
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF4A3F3A), width: 1.5),
          textStyle: _appFont(
            null,
            fontWeight: FontWeight.bold,
          ).copyWith(fontSize: 16),
        ),
      ),

      // Chip Theme for dark mode
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkPrimary,
        disabledColor: darkCard,
        labelStyle: _appFont(
          null,
          fontWeight: FontWeight.w600,
        ).copyWith(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: const BorderSide(color: Color(0xFF4A3F3A)),
      ),

      // AppBar Theme for dark mode
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _appFont(
          null,
          fontWeight: FontWeight.bold,
        ).copyWith(fontSize: 18, color: const Color(0xFFF5EDE8)),
        iconTheme: const IconThemeData(color: Color(0xFFF5EDE8)),
      ),

      // Bottom Navigation for dark mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Color(0xFF9C8579),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider for dark mode
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A322E),
        thickness: 1,
      ),

      textTheme: _buildTextTheme(base.textTheme).apply(
        displayColor: const Color(0xFFF5EDE8),
        bodyColor: const Color(0xFFEDE0DE),
        fontFamilyFallback: ['Roboto'],
      ),

      extensions: const [BrandColors(success: accentGreen, danger: accentRed)],
    );
  }
}
