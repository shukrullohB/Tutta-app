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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
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

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF7A45),
      onPrimary: Color(0xFF2B1208),
      secondary: Color(0xFFFFA86B),
      onSecondary: Color(0xFF2B1208),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF2B0A0A),
      surface: Color(0xFF1E1713),
      onSurface: Color(0xFFF2E9E3),
      surfaceContainerHighest: Color(0xFF2A211C),
      onSurfaceVariant: Color(0xFFD4C2B8),
      outline: Color(0xFF7E675B),
      outlineVariant: Color(0xFF4F4038),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF2E9E3),
      onInverseSurface: Color(0xFF2D1C14),
      inversePrimary: Color(0xFFE5481C),
      tertiary: Color(0xFFE8CFAE),
      onTertiary: Color(0xFF2D1C14),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: const Color(0xFF17120F),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF2E9E3),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2E9E3),
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFFF2E9E3),
        ),
        bodyMedium: TextStyle(height: 1.35, color: Color(0xFFF2E9E3)),
        bodySmall: TextStyle(color: Color(0xFFD4C2B8)),
      ),
      dividerColor: const Color(0x33FFFFFF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF241D18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F4038)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F4038)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7A45)),
        ),
        labelStyle: const TextStyle(color: Color(0xFFD4C2B8)),
        hintStyle: const TextStyle(color: Color(0xFFB79E92)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x66FF7A45);
          }
          return const Color(0x334F4038);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF7A45);
          }
          return const Color(0xFFB79E92);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFFF2E9E3),
        textColor: Color(0xFFF2E9E3),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1713),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4F4038)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF1E1713),
        indicatorColor: Color(0x33FF7A45),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: Color(0xFFD4C2B8)),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: Color(0xFFD4C2B8), fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A211C),
        selectedColor: const Color(0x33FF7A45),
        disabledColor: const Color(0x332A211C),
        side: const BorderSide(color: Color(0xFF4F4038)),
        labelStyle: const TextStyle(
          color: Color(0xFFF2E9E3),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(color: Color(0xFFFF7A45)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: const Color(0xFFFF7A45),
          foregroundColor: const Color(0xFF2B1208),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFA86B)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          foregroundColor: const Color(0xFFF2E9E3),
          side: const BorderSide(color: Color(0xFF4F4038)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1713),
        modalBackgroundColor: Color(0xFF1E1713),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1713)),
    );
  }
}
