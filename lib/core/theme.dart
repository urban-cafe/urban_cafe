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
  // Popular "Coffee Shop App" Palette (Figma Reference Style)
  static const Color primary = Color(0xFFC67C4E); // Copper / Burnt Orange
  static const Color secondary = Color(0xFFEDD6C8); // Light Beige
  static const Color tertiary = Color(0xFF313131); // Dark Charcoal

  static const Color neutralBg = Color(0xFFF9F9F9); // Clean White/Grey
  static const Color surface = Colors.white;

  // Accents
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentRed = Color(0xFFC62828);

  static TextTheme _buildTextTheme(TextTheme base) {
    // SORA: The signature font for this specific design style
    return base.copyWith(
      displayLarge: GoogleFonts.sora(textStyle: base.displayLarge, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.sora(textStyle: base.displayMedium, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.sora(textStyle: base.displaySmall, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.sora(textStyle: base.headlineLarge, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.sora(textStyle: base.headlineMedium, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.sora(textStyle: base.headlineSmall, fontWeight: FontWeight.w600),

      titleLarge: GoogleFonts.sora(textStyle: base.titleLarge, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.sora(textStyle: base.titleMedium, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.sora(textStyle: base.titleSmall, fontWeight: FontWeight.bold),

      bodyLarge: GoogleFonts.sora(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.sora(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.sora(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.sora(textStyle: base.labelLarge, fontWeight: FontWeight.bold),
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
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
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
        labelStyle: GoogleFonts.sora(color: Colors.grey.shade700),
        hintStyle: GoogleFonts.sora(color: Colors.grey.shade400),
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
        titleTextStyle: GoogleFonts.sora(color: const Color(0xFF2C2C2C), fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
      ),
      extensions: const <ThemeExtension<dynamic>>[BrandColors(success: accentGreen, danger: accentRed)],
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    const darkBg = Color(0xFF272727); // Deep Charcoal (Figma Style)
    const darkSurface = Color(0xFF313131); // Slightly lighter

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary, // Copper Orange
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: const Color(0xFF2C2C2C),
        surface: darkBg,
        surfaceContainer: darkSurface,
      ),
      textTheme: _buildTextTheme(base.textTheme).apply(displayColor: Colors.white, bodyColor: const Color(0xFFE0E0E0), fontFamilyFallback: ['Roboto']),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.sora(color: Colors.grey.shade400),
        hintStyle: GoogleFonts.sora(color: Colors.grey.shade600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkSurface,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[BrandColors(success: accentGreen, danger: accentRed)],
    );
  }
}
