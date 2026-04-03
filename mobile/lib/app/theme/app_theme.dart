import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const _background = AppColors.background;
  static const _surface = AppColors.surface;
  static const _surfaceRaised = AppColors.surfaceTint;
  static const _accent = AppColors.primary;
  static const _secondary = AppColors.secondary;
  static const _text = AppColors.text;

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _accent,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: _surface,
      onSurface: _text,
      surfaceContainerHighest: _surfaceRaised,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF3B2418),
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primarySoft,
      tertiary: AppColors.secondarySoft,
      onTertiary: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _text,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: _text),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: _text),
        bodyMedium: TextStyle(height: 1.35, color: _text),
        bodySmall: TextStyle(color: AppColors.textMuted),
      ),
      dividerColor: const Color(0x1F102040),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.iconMuted),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x66F15A24);
          }
          return const Color(0x33F2A120);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _accent;
          }
          return AppColors.iconMuted;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _text,
        textColor: _text,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x26F15A24),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: AppColors.textMuted),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceTint,
        selectedColor: const Color(0x26F15A24),
        disabledColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: _text, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: _accent),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          foregroundColor: _text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        modalBackgroundColor: Color(0xFFFFFFFF),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFFFFFFF)),
    );
  }

  static ThemeData get dark => light;
}
