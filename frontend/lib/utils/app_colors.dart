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

  // ── Light Mode ──────────────────────────────────────────────────────────────
  static const light = AppColors(
    background:    Color(0xFFF8FAFC),
    surface:       Color(0xFFFFFFFF),
    primary:       Color(0xFFFF6B00),
    secondary:     Color(0xFFFFE8D6),
    accent:        Color(0xFFFF6B00),
    textPrimary:   Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    border:        Color(0xFFE2E8F0),
  );

  // ── Dark Mode ───────────────────────────────────────────────────────────────
  static const dark = AppColors(
    background:    Color(0xFF0B0B0B),
    surface:       Color(0xFF1A1A1A),
    primary:       Color(0xFFFF6B00),
    secondary:     Color(0xFF2A2A2A),
    accent:        Color(0xFFFF6B00),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1AA),
    border:        Color(0xFF27272A),
  );

  // ── AI Mode ─────────────────────────────────────────────────────────────────
  static final ai = AppColors(
    background:    const Color(0xFF0F0F1A),
    surface:       const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    primary:       const Color(0xFF7C3AED), // AI Purple
    secondary:     const Color(0xFF00F5D4), // AI Cyan
    accent:        const Color(0xFFFF6B00), // Brand Orange (kept consistent)
    textPrimary:   const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFF94A3B8),
    border:        const Color(0x1FFFFFFF), // rgba(255,255,255,0.12)
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryGradient: const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF00F5D4)],
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
