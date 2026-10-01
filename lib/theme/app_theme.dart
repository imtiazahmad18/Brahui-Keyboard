import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5CB4E8),
        primary: const Color(0xFF123A5E),
        secondary: const Color(0xFF5CB4E8),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F7FB),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD7E7F2)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF123A5E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5CB4E8),
        primary: const Color(0xFF5CB4E8),
        secondary: const Color(0xFF8CCDF2),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B2137),
      cardTheme: CardThemeData(
        color: const Color(0xFF123A5E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF214D70)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF123A5E),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
      ),
    );
  }
}
