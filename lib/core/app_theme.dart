import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5B3FD0);
  static const Color dark = Color(0xFF3B2A99);
  static const Color background = Color(0xFFF6F4FF);
  static const Color text = Color(0xFF1F2340);
  static const Color textLight = Color(0xFF718096);
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2A);
  static const Color darkText = Color(0xFFEDEDF5);
}

extension ThemeColors on BuildContext {
  Color get cardBg => Theme.of(this).colorScheme.surface;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final onSurface = isDark ? AppColors.darkText : AppColors.text;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? const Color(0xFF343446) : const Color(0xFFE2E8F0);

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFFB4A5FF) : AppColors.primary,
      surface: surface,
      onSurface: onSurface,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}