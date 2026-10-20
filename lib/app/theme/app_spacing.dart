import 'package:flutter/material.dart';

/// Spacing tokens for Ezze Break (4px grid base)
class Spacing {
  static const double xs = 4; // Micro gaps
  static const double sm = 8; // Between related elements
  static const double md = 12; // Standard content gap
  static const double lg = 16; // Between sections / internal card padding
  static const double xl = 20; // Major section padding / hero card padding
  static const double xxl = 24; // Screen edge padding / between sections
  static const double xxxl = 32; // Large separators
  static const double huge = 48; // Hero spacing
  static const double massive = 64; // Splash / onboarding spacing

  // Standard Screen Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: xxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets heroCardPadding = EdgeInsets.all(xl);
}

/// Border Radii tokens for Ezze Break
class Radii {
  static const double xs = 6; // Small badges, chips
  static const double sm = 8; // Input fields
  static const double md = 12; // Standard cards, buttons
  static const double lg = 16; // Hero cards, dialogs
  static const double xl = 20; // Bottom sheets
  static const double xxl = 24; // Onboarding cards
  static const double full = 999; // Circular (avatars, FAB, status badges)

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}
