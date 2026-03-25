import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _background = Color(0xFF0E0E14);
  static const _surface = Color(0xFF14141E);
  static const _surfaceRaised = Color(0xFF1C1C28);
  static const _accent = Color(0xFFC8A84B);
  static const _onDark = Color(0xFFF5F5FA);

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _accent,
      onPrimary: Color(0xFF1A1302),
      secondary: _accent,
      onSecondary: Color(0xFF1A1302),
      error: Color(0xFFFF6E6E),
      onError: Color(0xFF1A0000),
      surface: _surface,
      onSurface: _onDark,
      surfaceContainerHighest: _surfaceRaised,
      onSurfaceVariant: Color(0xFF9FA1B3),
      outline: Color(0xFF2E2F40),
      outlineVariant: Color(0xFF232434),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF1F1F6),
      onInverseSurface: Color(0xFF1B1B25),
      inversePrimary: Color(0xFF8E7530),
      tertiary: Color(0xFFBCA57A),
      onTertiary: Color(0xFF1A1302),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _background,
        foregroundColor: _onDark,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: _onDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: _onDark),
        bodyMedium: TextStyle(height: 1.35, color: _onDark),
        bodySmall: TextStyle(color: Color(0xFF9FA1B3)),
      ),
      dividerColor: const Color(0x1FFFFFFF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF232434)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2B3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9FA1B3)),
        hintStyle: const TextStyle(color: Color(0xFF6C6E80)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x66C8A84B);
          }
          return const Color(0x332E2F40);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _accent;
          }
          return const Color(0xFF9FA1B3);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _onDark,
        textColor: _onDark,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: Color(0x33C8A84B),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: Color(0xFFB9BBC9)),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: Color(0xFFB9BBC9), fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x1AFFFFFF),
        selectedColor: const Color(0x33C8A84B),
        disabledColor: const Color(0x222E2F40),
        side: const BorderSide(color: Color(0x33FFFFFF)),
        labelStyle: const TextStyle(
          color: _onDark,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(color: _accent),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: _accent,
          foregroundColor: const Color(0xFF1A1302),
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
          foregroundColor: _onDark,
          side: const BorderSide(color: Color(0x33FFFFFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        modalBackgroundColor: _surface,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: _surface),
    );
  }

  static ThemeData get dark => light;
}
