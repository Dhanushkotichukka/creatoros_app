import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

/// The three appearance modes supported by CreatorOS.
enum AppMode { light, dark, ai }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_mode';

  AppMode _appMode = AppMode.dark;

  AppMode get appMode => _appMode;

  /// Convenience helpers used by existing widgets that check `isDark`.
  bool get isDark  => _appMode == AppMode.dark || _appMode == AppMode.ai;
  bool get isLight => _appMode == AppMode.light;
  bool get isAI    => _appMode == AppMode.ai;

  /// The Flutter ThemeMode fed to MaterialApp.
  ThemeMode get mode {
    switch (_appMode) {
      case AppMode.light: return ThemeMode.light;
      case AppMode.dark:  return ThemeMode.dark;
      case AppMode.ai:    return ThemeMode.dark;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey) ?? 'dark';
    _appMode = _modeFromString(saved);
    notifyListeners();
  }

  AppMode _modeFromString(String s) {
    switch (s) {
      case 'light': return AppMode.light;
      case 'ai':    return AppMode.ai;
      default:      return AppMode.dark;
    }
  }

  Future<void> setMode(AppMode mode) async {
    _appMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void setLight() => setMode(AppMode.light);
  void setDark()  => setMode(AppMode.dark);
  void setAI()    => setMode(AppMode.ai);

  void toggle() => setMode(_appMode == AppMode.light ? AppMode.dark : AppMode.light);

  // ── LIGHT THEME ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    // Inline the palette values — no const access on object fields
    const bgColor          = Color(0xFFFFFFFF); // White Background
    const surfaceColor     = Color(0xFFFFFFFF); // White Surface
    const primaryColor     = Color(0xFFF16E00); // Main Orange
    const secondaryColor   = Color(0xFF000000); // Deep Black
    const textPrimaryColor = Color(0xFF000000); // Deep Black
    const textSecColor     = Color(0xFF757575); // Medium Grey
    const borderColor      = Color(0xFFDDDDDD); // Light Grey Border

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      extensions: <ThemeExtension<dynamic>>[AppColors.light],
      colorScheme: const ColorScheme.light(
        primary:   primaryColor,
        secondary: primaryColor,
        surface:   surfaceColor,
        onSurface: textPrimaryColor,
        outline:   borderColor,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor:  bgColor,
        foregroundColor:  textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     surfaceColor,
        selectedItemColor:   primaryColor,
        unselectedItemColor: textSecColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w800, fontSize: 32),
        displayMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w700, fontSize: 28),
        titleLarge:    TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w800, fontSize: 22),
        titleMedium:   TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w700, fontSize: 18),
        bodyLarge:     TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium:    TextStyle(color: textPrimaryColor, fontSize: 14),
        bodySmall:     TextStyle(color: textSecColor,     fontSize: 12),
      ),
      dividerColor: borderColor,
      iconTheme: const IconThemeData(color: textSecColor),
    );
  }

  // ── DARK THEME ───────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bgColor          = Color(0xFF0A0A0A); // Rich near-black
    const surfaceColor     = Color(0xFF141414); // Bento card
    const primaryColor     = Color(0xFFFF6B00); // Vibrant orange
    const textPrimaryColor = Color(0xFFFFFFFF);
    const textSecColor     = Color(0xFF888888);
    const borderColor      = Color(0xFF242424);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      extensions: <ThemeExtension<dynamic>>[AppColors.dark],
      colorScheme: const ColorScheme.dark(
        primary:   primaryColor,
        secondary: primaryColor,
        surface:   surfaceColor,
        onSurface: textPrimaryColor,
        outline:   borderColor,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor:   bgColor,
        foregroundColor:   textPrimaryColor,
        elevation: 0,
        shadowColor:       Colors.transparent,
        surfaceTintColor:  Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5907), // Vibrant Orange in dark mode for pop
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     surfaceColor,
        selectedItemColor:   primaryColor,
        unselectedItemColor: textSecColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge:   TextStyle(color: textPrimaryColor, fontFamily: 'Inter'),
        bodyMedium:  TextStyle(color: textPrimaryColor, fontFamily: 'Inter'),
        bodySmall:   TextStyle(color: textSecColor,     fontFamily: 'Inter'),
        titleLarge:  TextStyle(color: textPrimaryColor, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimaryColor, fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
      dividerColor: borderColor,
      iconTheme: const IconThemeData(color: textSecColor),
    );
  }

  // ── AI THEME ─────────────────────────────────────────────────────────────────
  static ThemeData get aiTheme {
    const bgColor          = Color(0xFF0F0F1A);
    const surfaceColor     = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
    const primaryColor     = Color(0xFF8B5CF6); // AI Purple
    const secondaryColor   = Color(0xFF00F5D4); // AI Cyan
    const accentColor      = Color(0xFF86D28A); // Soft Lime
    const textPrimaryColor = Color(0xFFFFFFFF);
    const textSecColor     = Color(0xFF94A3B8);
    const borderColor      = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)

    final aiColors = AppColors.ai;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      extensions: <ThemeExtension<dynamic>>[aiColors],
      colorScheme: const ColorScheme.dark(
        primary:   primaryColor,
        secondary: secondaryColor,
        surface:   bgColor,
        onSurface: textPrimaryColor,
        outline:   borderColor,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor:   bgColor,
        foregroundColor:   textPrimaryColor,
        elevation: 0,
        shadowColor:       Colors.transparent,
        surfaceTintColor:  Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: const CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     bgColor,
        selectedItemColor:   accentColor, // orange stays consistent
        unselectedItemColor: textSecColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge:   TextStyle(color: textPrimaryColor, fontFamily: 'Inter'),
        bodyMedium:  TextStyle(color: textPrimaryColor, fontFamily: 'Inter'),
        bodySmall:   TextStyle(color: textSecColor,     fontFamily: 'Inter'),
        titleLarge:  TextStyle(color: textPrimaryColor, fontFamily: 'Inter', fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimaryColor, fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
      dividerColor: borderColor,
      iconTheme: const IconThemeData(color: textSecColor),
    );
  }
}
