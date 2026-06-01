import 'package:flutter/material.dart';

/// Consistent spacing scale used throughout the app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard screen padding.
  static const EdgeInsets screenPadding = EdgeInsets.all(xl);

  /// Card internal padding.
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(vertical: xxl, horizontal: lg);

  /// List item padding.
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(vertical: sm, horizontal: lg);
}

/// Consistent border radius scale.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static final BorderRadius inputBorder = BorderRadius.circular(sm);
  static final BorderRadius cardBorder = BorderRadius.circular(md);
  static final BorderRadius heroCardBorder = BorderRadius.circular(xl);
  static final BorderRadius modalBorder = BorderRadius.circular(lg);
  static final BorderRadius pillBorder = BorderRadius.circular(pill);
}

/// Consistent icon sizes.
abstract final class AppIconSize {
  static const double xs = 14;
  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double hero = 96;
}

/// Consistent animation durations.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration splash = Duration(milliseconds: 1500);
}
