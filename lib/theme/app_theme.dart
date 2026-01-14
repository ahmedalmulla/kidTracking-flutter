import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF64B5F6), // Soft Blue
      secondary: const Color(0xFFAED581), // Soft Green
      tertiary: const Color(0xFFFFB74D), // Soft Orange
      background: const Color(0xFFF5F7FA),
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: const TextStyle(fontWeight: FontWeight.bold),
      titleLarge: const TextStyle(fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
