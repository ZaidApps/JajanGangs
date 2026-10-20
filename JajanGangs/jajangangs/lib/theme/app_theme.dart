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
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      barrierColor: const Color(0xA6102639),
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFD9E8DF)),
      ),
      titleTextStyle: const TextStyle(
        color: Color(0xFF102C42),
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFF465E6B),
        fontSize: 16,
        height: 1.5,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: const Color(0x40102C42),
      position: PopupMenuPosition.under,
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD6E5DD)),
      ),
      textStyle: const TextStyle(
        color: Color(0xFF102C42),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.cream),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(12),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFD6E5DD)),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Color(0xFF102C42)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)
              ? const Color(0x25158A79)
              : null,
        ),
      ),
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
