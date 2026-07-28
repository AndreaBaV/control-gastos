import 'package:flutter/material.dart';

class AppTheme {
  static const _surface = Color(0xFFF5F4F1);
  static const _onSurface = Color(0xFF141413);
  static const _primary = Color(0xFF2F4F4F);

  static ThemeData light() {
    final scheme = ColorScheme.light(
      surface: _surface,
      onSurface: _onSurface,
      primary: _primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF6B5B4F),
      onSecondary: Colors.white,
      outline: const Color(0xFFD9D6D0),
      error: const Color(0xFFB00020),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: _onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _primary : _onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _primary : _onSurface.withValues(alpha: 0.45),
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: _onSurface,
        ),
        bodyLarge: TextStyle(color: _onSurface, height: 1.35),
        bodyMedium: TextStyle(color: _onSurface, height: 1.35),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
