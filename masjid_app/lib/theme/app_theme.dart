import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted from the Ahlul Bayt Mosque logo
  static const Color navyBlue = Color(0xFF1A4F7A);   // deep logo blue
  static const Color navyDark = Color(0xFF0F3251);   // darker variant
  static const Color gold = Color(0xFFC9A84C);        // warm gold from logo line
  static const Color goldLight = Color(0xFFE2C06E);

  // Dark theme palette
  static const Color bgDark = Color(0xFF06111E);
  static const Color surfaceDark = Color(0xFF0D1F33);
  static const Color surfaceVariant = Color(0xFF122840);
  static const Color textSecondary = Color(0xFF90A4AE);

  // Light theme palette (matches logo background)
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEAEFF5);
  static const Color textSecondaryLight = Color(0xFF5A7A9A);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: navyBlue,
      secondary: gold,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: bgDark,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 6,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: navyBlue,
      secondary: gold,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF0D1F33),
    ),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: navyBlue,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    cardTheme: CardTheme(
      color: surfaceLight,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.black38),
    ),
  );
}
