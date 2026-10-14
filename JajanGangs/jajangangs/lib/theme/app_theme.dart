import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF25261F);
  static const cream = Color(0xFFFFFAEF);
  static const lime = Color(0xFFD5F567);
  static const orange = Color(0xFFFF8055);
  static const lavender = Color(0xFFC9BEFF);
}

abstract final class AppSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      primary: AppColors.ink,
      onPrimary: AppColors.cream,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 48,
        height: 1.04,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(AppSpacing.medium),
    ),
  );
}
