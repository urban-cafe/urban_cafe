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
  static const Color primary = Color(0xFF8B5E3C);
  static const Color accent = Color(0xFFB08968);
  static const Color neutralBg = Color(0xFFF7F7F7);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, primary: primary, onPrimary: Colors.white, secondary: accent, onSecondary: Colors.white, surface: neutralBg),
    textTheme: GoogleFonts.loraTextTheme(ThemeData.light().textTheme).apply(displayColor: const Color(0xFF4E3B2F), bodyColor: const Color(0xFF4E3B2F)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    scaffoldBackgroundColor: neutralBg,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    extensions: const <ThemeExtension<dynamic>>[BrandColors(success: Color(0xFF2E7D32), danger: Color(0xFFC62828))],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, primary: primary, onPrimary: Colors.white, secondary: accent, onSecondary: Colors.white, surface: const Color(0xFF1F1A17), onSurface: const Color(0xFFEDE3DD)),
    textTheme: GoogleFonts.loraTextTheme(ThemeData.dark().textTheme).apply(displayColor: Colors.white, bodyColor: Colors.white),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(style: ButtonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent),
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[BrandColors(success: Color(0xFF81C784), danger: Color(0xFFE57373))],
  );
}
