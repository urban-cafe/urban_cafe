import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.success, required this.danger});
  final Color success;
  final Color danger;

  @override
  BrandColors copyWith({Color? success, Color? danger}) => BrandColors(success: success ?? this.success, danger: danger ?? this.danger);

  @override
  ThemeExtension<BrandColors> lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(success: Color.lerp(success, other.success, t)!, danger: Color.lerp(danger, other.danger, t)!);
  }
}

class AppTheme {
  // Richer Coffee Palette (Restored & Enhanced)
  static const Color primary = Color(0xFF6F4E37); // Classic Coffee Bean
  static const Color secondary = Color(0xFFC19A6B); // Latte Art / Warm Gold
  static const Color tertiary = Color(0xFF2C3E50); // Dark Slate (Modern contrast)

  static const Color neutralBg = Color(0xFFFDFBF7); // Warm Paper (Retained as it's better than pure white)
  static const Color surface = Colors.white;

  // Accents (Retained as they are good)
  static const Color accentGreen = Color(0xFF2E7D32); // Standard Success Green
  static const Color accentRed = Color(0xFFC62828); // Standard Error Red

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      // Fraunces: A "Soft Serif" - warm, premium, distinct (Perfect for Coffee)
      displayLarge: GoogleFonts.fraunces(textStyle: base.displayLarge, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.fraunces(textStyle: base.displayMedium, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.fraunces(textStyle: base.displaySmall, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.fraunces(textStyle: base.headlineLarge, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.fraunces(textStyle: base.headlineMedium, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.fraunces(textStyle: base.headlineSmall, fontWeight: FontWeight.w600),

      // Urbanist: Modern, geometric but friendly sans-serif
      titleLarge: GoogleFonts.urbanist(textStyle: base.titleLarge, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.urbanist(textStyle: base.titleMedium, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.urbanist(textStyle: base.titleSmall, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.urbanist(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.urbanist(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.urbanist(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.urbanist(textStyle: base.labelLarge, fontWeight: FontWeight.bold),
    );
  }

  static ThemeData get theme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary, tertiary: tertiary, surface: neutralBg, brightness: Brightness.light),
      textTheme: _buildTextTheme(base.textTheme).apply(displayColor: const Color(0xFF2C2C2C), bodyColor: const Color(0xFF3C3C3C), fontFamilyFallback: ['Roboto']),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.bold, fontSize: 16),
          side: const BorderSide(width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: GoogleFonts.urbanist(color: Colors.grey.shade700),
        hintStyle: GoogleFonts.urbanist(color: Colors.grey.shade400),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      scaffoldBackgroundColor: neutralBg,
      appBarTheme: AppBarTheme(
        backgroundColor: neutralBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(color: const Color(0xFF2C2C2C), fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
      ),
      extensions: const <ThemeExtension<dynamic>>[BrandColors(success: accentGreen, danger: accentRed)],
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    const darkBg = Color(0xFF1A1614); // Very Dark Brown/Black
    const darkSurface = Color(0xFF26211E);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: secondary, // Use lighter gold/latte for primary in dark mode
        onPrimary: const Color(0xFF2C2C2C),
        secondary: primary,
        surface: darkBg,
        surfaceContainer: darkSurface,
      ),
      textTheme: _buildTextTheme(base.textTheme).apply(displayColor: const Color(0xFFEDE3DD), bodyColor: const Color(0xFFD7CCC8), fontFamilyFallback: ['Roboto']),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(color: const Color(0xFFEDE3DD), fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Color(0xFFEDE3DD)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        labelStyle: GoogleFonts.urbanist(color: Colors.grey.shade400),
        hintStyle: GoogleFonts.urbanist(color: Colors.grey.shade600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkSurface,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: const Color(0xFF2C2C2C),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[BrandColors(success: accentGreen, danger: accentRed)],
    );
  }
}
