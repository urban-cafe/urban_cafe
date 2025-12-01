import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF455A64);
  static const Color accent = Color(0xFF80CBC4);
  static const Color neutralBg = Color(0xFFF7F7F7);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          background: neutralBg,
        ),
        scaffoldBackgroundColor: neutralBg,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
