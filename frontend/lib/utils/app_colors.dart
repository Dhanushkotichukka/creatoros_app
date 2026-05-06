import 'package:flutter/material.dart';

/// Semantic color tokens for every app mode.
/// Access via: `Theme.of(context).extension<AppColors>()!`
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color primary;   // Brand / action colour (orange in Light & Dark; purple in AI)
  final Color secondary; // Soft tint / secondary surface
  final Color accent;    // For AI mode this is orange; identical to primary in other modes
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Gradient that should be applied to backgrounds / hero areas in AI Mode.
  /// Is null in Light and Dark modes.
  final Gradient? backgroundGradient;

  /// Gradient for the primary action button.
  final Gradient? primaryGradient;

  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    this.backgroundGradient,
    this.primaryGradient,
  });

  static const List<Color> pastels = [
    Color(0xFFD0E8FD), // Soft Blue
    Color(0xFFFDE4D0), // Soft Peach
    Color(0xFFE1D0FD), // Soft Purple
    Color(0xFFD0FDE4), // Soft Green
    Color(0xFFFDD0E4), // Soft Pink
    Color(0xFFFCF3CF), // Soft Yellow
  ];

  // ── Light Mode ──────────────────────────────────────────────────────────────
  static const light = AppColors(
    background:    Color(0xFFFFFFFF), // White
    surface:       Color(0xFFFFFFFF), // White
    primary:       Color(0xFFF16E00), // Orange
    secondary:     Color(0xFF000000), // Black
    accent:        Color(0xFFF16E00), // Orange
    textPrimary:   Color(0xFF000000), // Black
    textSecondary: Color(0xFF757575), // Medium Grey for legibility
    border:        Color(0xFFDDDDDD), // Light Grey border
  );

  // ── Dark Mode ─────────────────────────────────────────────────────────
  static const dark = AppColors(
    background:    Color(0xFF0A0A0A), // Rich near-black (warm)
    surface:       Color(0xFF141414), // Bento card surface
    primary:       Color(0xFFFF6B00), // Vibrant orange
    secondary:     Color(0xFFFFFFFF), // White
    accent:        Color(0xFFFF6B00), // Orange accent
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    border:        Color(0xFF242424), // Subtle border
  );

  // ── AI Mode ─────────────────────────────────────────────────────────────────
  static final ai = AppColors(
    background:    const Color(0xFF0F0F1A),
    surface:       const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    primary:       const Color(0xFF8B5CF6), // AI Purple
    secondary:     const Color(0xFF00F5D4), // AI Cyan
    accent:        const Color(0xFFEF5907), // Vibrant Orange
    textPrimary:   const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFF94A3B8),
    border:        const Color(0x1FFFFFFF), // rgba(255,255,255,0.12)
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF00F5D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ── ThemeExtension overrides ─────────────────────────────────────────────────
  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Gradient? backgroundGradient,
    Gradient? primaryGradient,
  }) {
    return AppColors(
      background:         background         ?? this.background,
      surface:            surface            ?? this.surface,
      primary:            primary            ?? this.primary,
      secondary:          secondary          ?? this.secondary,
      accent:             accent             ?? this.accent,
      textPrimary:        textPrimary        ?? this.textPrimary,
      textSecondary:      textSecondary      ?? this.textSecondary,
      border:             border             ?? this.border,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      primaryGradient:    primaryGradient    ?? this.primaryGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      primary:       Color.lerp(primary,       other.primary,       t)!,
      secondary:     Color.lerp(secondary,     other.secondary,     t)!,
      accent:        Color.lerp(accent,        other.accent,        t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      // Gradients don't lerp — keep target
      backgroundGradient: other.backgroundGradient,
      primaryGradient:    other.primaryGradient,
    );
  }
}
