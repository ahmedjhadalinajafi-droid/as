import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color gold = Color(0xFFFFD700);
  static const Color bgDark = Color(0xFF07111F);
  static const Color surface = Color(0xFF0F2035);
  static const Color surfaceVariant = Color(0xFF172D47);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color accent = Color(0xFF43A047);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryGreen,
          secondary: gold,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: bgDark,
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
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
          color: surface,
          elevation: 6,
          shadowColor: Colors.black54,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
