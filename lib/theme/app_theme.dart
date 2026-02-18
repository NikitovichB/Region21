import 'package:flutter/material.dart';

class AppTheme {
  static const orange = Color(0xFFFF7A00);
  static const dark = Color(0xFF0E0F12);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
