import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkSaved = prefs.getBool(_themeKey) ?? true; // Default to dark
    _mode = isDarkSaved ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  void setDark() async {
    _mode = ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, true);
  }

  void setLight() async {
    _mode = ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, false);
  }

  // ────────────────── LIGHT THEME ──────────────────
  static ThemeData get lightTheme {
    const primary = Color(0xFFFF6A3D);
    const accent = Color(0xFFFFB199);
    const bg = Color(0xFFFAFAF8);
    const surface = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF1E1E1E);
    const textSecondary = Color(0xFF6B6B6B);
    const border = Color(0xFFE5E5E5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textPrimary, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: textSecondary, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
      dividerColor: border,
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }

  // ────────────────── DARK THEME ──────────────────
  static ThemeData get darkTheme {
    const bg = Color(0xFF0F0F1A);
    const surface = Color(0xFF1A1A2E);
    const primary = Color(0xFF6C63FF);
    const orange = Color(0xFFFF6A3D);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFFA0A0B0);
    const border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: orange,
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: orange,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textPrimary, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: textSecondary, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
      dividerColor: border,
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }
}
