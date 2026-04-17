import 'package:flutter/material.dart';

/// Breakpoints used consistently across the entire CreatorOS app.
///
/// Usage:
///   final r = Responsive.of(context);
///   if (r.isWeb) { ... }
///   int cols = r.gridColumns(mobile: 2, tablet: 4, web: 6);
///   double pad = r.value(mobile: 12, tablet: 16, web: 24);

enum DeviceType { mobile, tablet, web }

class Responsive {
  final double width;
  final double height;
  final DeviceType deviceType;

  const Responsive._({
    required this.width,
    required this.height,
    required this.deviceType,
  });

  factory Responsive.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Responsive._(
      width: size.width,
      height: size.height,
      deviceType: _resolve(size.width),
    );
  }

  static DeviceType _resolve(double width) {
    if (width >= 900) return DeviceType.web;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isWeb => deviceType == DeviceType.web;

  /// Returns a value based on device type.
  T value<T>({required T mobile, required T tablet, required T web}) {
    switch (deviceType) {
      case DeviceType.web:    return web;
      case DeviceType.tablet: return tablet;
      case DeviceType.mobile: return mobile;
    }
  }

  /// Shorthand for numeric (double) values.
  double size({required double mobile, required double tablet, required double web}) {
    return value(mobile: mobile, tablet: tablet, web: web);
  }

  /// Horizontal content padding — tighter on mobile, spaced on web.
  EdgeInsets get contentPadding => EdgeInsets.symmetric(
    horizontal: value(mobile: 14.0, tablet: 20.0, web: 28.0),
    vertical: value(mobile: 12.0, tablet: 16.0, web: 20.0),
  );

  /// Horizontal-only padding shorthand.
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
    horizontal: value(mobile: 14.0, tablet: 20.0, web: 28.0),
  );

  /// Grid column count.
  int gridColumns({int mobile = 2, int tablet = 3, int web = 4}) {
    return value(mobile: mobile, tablet: tablet, web: web);
  }

  /// Font size helper — scales title / body / small.
  double get titleFontSize => value(mobile: 20.0, tablet: 22.0, web: 24.0);
  double get bodyFontSize  => value(mobile: 14.0, tablet: 15.0, web: 15.0);
  double get smallFontSize => value(mobile: 11.0, tablet: 12.0, web: 12.0);

  /// Card border radius.
  double get cardRadius => value(mobile: 12.0, tablet: 14.0, web: 16.0);

  /// Card elevation.
  double get cardElevation => value(mobile: 1.0, tablet: 2.0, web: 2.0);

  /// Spacing unit multiplier.
  double get spacing => value(mobile: 12.0, tablet: 16.0, web: 20.0);

  // ─── Convenience static methods ─────────────────────────────────────────────

  static bool isMobileSize(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTabletSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 900;
  }

  static bool isWebSize(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Note-grid columns: 6 on large web, 5 on narrow web, 4 on tablet, 2-3 on mobile
  static int noteGridColumns(double width) {
    if (width >= 1200) return 6;
    if (width >= 900)  return 5;
    if (width >= 600)  return 4;
    if (width >= 400)  return 3;
    return 2;
  }

  /// Note aspect ratio — compact cards on web, taller on mobile
  static double noteAspectRatio(double width) {
    if (width >= 900) return 0.75;
    if (width >= 600) return 0.8;
    return 0.85;
  }

  /// Storage grid (Videos/Images/Sounds/Edits): always 4 but smaller on mobile
  static int storageGridColumns(double width) {
    if (width >= 600) return 4;
    return 2; // on very small screens, show 2x2
  }

  /// Platform card grid (Connect Platforms view): 1 on mobile, 2 on tablet, 3 on web
  static int platformCardColumns(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Analytics stat grid: 2 on mobile, 3 on tablet, 4 on web
  static int statGridColumns(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }
}

// ─── Responsive layout builder helpers ───────────────────────────────────────

/// Wraps mobile/web into a side-by-side layout on web, vertical on mobile.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final List<int> flexValues;
  final double spacing;
  final double breakpoint;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.flexValues = const [],
    this.spacing = 24,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= breakpoint;
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(
              flex: flexValues.length > i ? flexValues[i] : 1,
              child: children[i],
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}

/// Max-width constrained container (prevents content from stretching on huge screens).
class MaxWidthBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
