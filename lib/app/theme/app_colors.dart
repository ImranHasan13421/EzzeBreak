import 'package:flutter/material.dart';

/// Design tokens for Ezze Break (v2.0)
class AppColors {
  // Brand colors
  static const Color brandRed = Color(0xFFE63946); // Hero accent
  static const Color brandRedDark = Color(0xFFCC2936); // Pressed state
  static const Color brandRedLight = Color(0xFFFF6B6B); // Highlights

  // Secondary accent (success/positive states)
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentGreenDark = Color(0xFF05B88A);

  // Tertiary accent (informational)
  static const Color accentBlue = Color(0xFF118AB2);
  static const Color accentBlueDark = Color(0xFF0D7A9F);

  // Warning/Override
  static const Color accentAmber = Color(0xFFFFC857);
  static const Color accentAmberDark = Color(0xFFE6B44E);

  // Dark Theme Palette
  static const Color darkBg0 = Color(0xFF09090B); // Scaffold background
  static const Color darkBg1 = Color(0xFF111113); // Card backgrounds
  static const Color darkBg2 = Color(0xFF1A1A1E); // Elevated cards, modals
  static const Color darkBg3 = Color(0xFF232328); // Input fields, dropdown bg

  // Dark Text Hierarchy
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);
  static const Color darkTextDisabled = Color(0xFF52525B);

  // Dark Borders & Dividers
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkDivider = Color(0xFF1F1F23);
  static const Color darkBorderFocused = Color(0xFFE63946);

  // Glassmorphism overlays
  static const Color darkGlass = Color(0x1AFFFFFF); // 10% white overlay
  static const Color darkGlassStroke = Color(0x33FFFFFF); // 20% white for glass borders

  // Light Theme Palette
  static const Color lightBg0 = Color(0xFFF8F9FA); // Scaffold background
  static const Color lightBg1 = Color(0xFFFFFFFF); // Card backgrounds
  static const Color lightBg2 = Color(0xFFF1F3F5); // Elevated cards
  static const Color lightBg3 = Color(0xFFE9ECEF); // Input fields

  // Light Text Hierarchy
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextTertiary = Color(0xFFADB5BD);
  static const Color lightTextDisabled = Color(0xFFCED4DA);

  // Light Borders & Dividers
  static const Color lightBorder = Color(0xFFE9ECEF);
  static const Color lightDivider = Color(0xFFF1F3F5);
  static const Color lightBorderFocused = Color(0xFFE63946);

  // Semantic Colors
  static const Color success = Color(0xFF06D6A0);
  static const Color successBg = Color(0x1A06D6A0);
  static const Color warning = Color(0xFFFFC857);
  static const Color warningBg = Color(0x1AFFC857);
  static const Color error = Color(0xFFEF476F);
  static const Color errorBg = Color(0x1AEF476F);
  static const Color info = Color(0xFF118AB2);
  static const Color infoBg = Color(0x1A118AB2);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgAccentGradient = LinearGradient(
    colors: [Color(0x0DE63946), Color(0x00E63946)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF04BF8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF1A1A1E), Color(0xFF232328), Color(0xFF1A1A1E)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
  );

  // Backward Compatibility Aliases
  static const Color primaryRed = brandRed;
  static const Color darkerRed = brandRedDark;
  static const Color softRed = Color(0xFFFCE7E9);
  static const Color black = Color(0xFF111111);
  static const Color deepBlack = darkBg0;
  static const Color white = Color(0xFFFFFFFF);
  static const Color neutralGray = darkTextTertiary;
  static const Color disabled = darkTextDisabled;

  static const Color darkBackground = darkBg0;
  static const Color darkSurface = darkBg1;
  static const Color darkElevated = darkBg2;
  static const Color darkPrimaryText = darkTextPrimary;
  static const Color darkSecondaryText = darkTextSecondary;
  static const Color darkAccent = brandRed;

  static const Color lightBackground = lightBg0;
  static const Color lightSurface = lightBg1;
  static const Color lightElevated = lightBg2;
  static const Color lightPrimaryText = lightTextPrimary;
  static const Color lightSecondaryText = lightTextSecondary;
  static const Color lightAccent = brandRed;
}
