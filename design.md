# Ezze Break — Production UI/UX Design System & Implementation Blueprint

> **Version:** 2.0.0  
> **Last Updated:** October 2026  
> **Author:** Senior UI/UX Engineering Team  
> **Purpose:** Complete, self-contained design specification. Any engineer or AI model should be able to implement the exact production-grade UI from this document alone.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Design Philosophy](#2-design-philosophy)
3. [Color System & Design Tokens](#3-color-system--design-tokens)
4. [Typography System](#4-typography-system)
5. [Spacing & Layout Grid](#5-spacing--layout-grid)
6. [Component Library](#6-component-library)
7. [Iconography](#7-iconography)
8. [Animation & Motion System](#8-animation--motion-system)
9. [Screen Specifications](#9-screen-specifications)
   - 9.1 [Splash Screen](#91-splash-screen)
   - 9.2 [Onboarding Flow](#92-onboarding-flow)
   - 9.3 [Dashboard (Home)](#93-dashboard-home)
   - 9.4 [My Apps (App Management)](#94-my-apps-app-management)
   - 9.5 [App Selector Bottom Sheet](#95-app-selector-bottom-sheet)
   - 9.6 [Rule Configuration Screen](#96-rule-configuration-screen)
   - 9.7 [Insights (Analytics)](#97-insights-analytics)
   - 9.8 [Break Enforcement Screen](#98-break-enforcement-screen)
   - 9.9 [Exercise Session Screen](#99-exercise-session-screen)
   - 9.10 [Exercise Library](#910-exercise-library)
   - 9.11 [Override Dialog](#911-override-dialog)
   - 9.12 [PIN Entry Screen](#912-pin-entry-screen)
   - 9.13 [Show PIN Screen](#913-show-pin-screen)
   - 9.14 [Profile Screen](#914-profile-screen)
   - 9.15 [Settings Screen](#915-settings-screen)
   - 9.16 [Reports / Export Screen](#916-reports--export-screen)
   - 9.17 [Native Restriction Overlay (Kotlin)](#917-native-restriction-overlay-kotlin)
10. [Navigation Architecture](#10-navigation-architecture)
11. [State Management Patterns](#11-state-management-patterns)
12. [Accessibility](#12-accessibility)
13. [Performance Guidelines](#13-performance-guidelines)
14. [File Structure](#14-file-structure)
15. [Implementation Checklist](#15-implementation-checklist)

---

## 1. Product Overview

**Ezze Break** is a 100% offline, zero-account, zero-cloud digital wellbeing companion for Android. It monitors foreground app usage, enforces session-based breaks with physical exercises, manages daily screen budgets, and provides analytics—all without ever connecting to the internet.

### Core Value Propositions
- **Offline-First Privacy:** No internet permissions, no telemetry, no accounts. SQLite + SharedPreferences only.
- **Active Break Enforcement:** Physical exercises (push-ups, squats, stretches) are required during breaks—not passive screen-off timers.
- **Rolling PIN Security:** An 8-digit deterministic PIN rotates every 24h, providing mindful friction before resuming app use.
- **Production-Grade UX:** Premium visual quality rivaling commercial digital wellbeing apps like Google Digital Wellbeing, Apple Screen Time, and Opal.

### Technical Stack
| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x / Dart |
| State Management | Riverpod 2.x |
| Local Database | sqflite |
| Preferences | SharedPreferences |
| Charts | fl_chart |
| PDF Export | pdf + open_filex |
| Native Android | Kotlin (MethodChannel) |
| Native Services | UsageStatsManager, AccessibilityService, OverlayWindow |

---

## 2. Design Philosophy

### 2.1 Core Principles

| Principle | Description |
|---|---|
| **Calm Computing** | Soothing, low-contrast dark mode as default. Light mode equally polished. Interface should feel restful, not anxiety-inducing. |
| **Glassmorphism Lite** | Subtle frosted glass effects on elevated surfaces. Not heavy blur—just enough to create depth hierarchy. |
| **Purposeful Motion** | Every animation communicates state change. No decorative motion. Spring curves for organic feel. |
| **Information Density** | Dashboard shows key metrics at a glance. Progressive disclosure for details. No scrolling for critical data. |
| **Haptic Feedback** | Light haptics on button taps, medium on destructive actions, heavy on PIN entry and break enforcement. |

### 2.2 Design Inspirations
- **Google Digital Wellbeing:** Clean data visualization, circular progress widgets
- **Apple Health:** Card-based layout, subtle gradients, smooth transitions
- **Opal App:** Premium dark mode, glassmorphic cards, vibrant accent colors
- **Samsung One UI:** Large touch targets, one-handed reachability, hierarchical typography

### 2.3 Key UX Principles
1. **Zero-learning-curve onboarding** — The app should be understandable within 10 seconds of opening.
2. **Positive reinforcement** — Celebrate completed breaks and exercises. Never shame the user.
3. **Friction where intentional** — PIN entry and exercise requirements are *features*, not bugs. Make the friction feel respectful.
4. **Glanceable dashboard** — Total usage, status, and next action visible without scrolling.

---

## 3. Color System & Design Tokens

### 3.1 Brand Colors

```dart
// Primary brand gradient
static const Color brandRed = Color(0xFFE63946);        // Hero accent
static const Color brandRedDark = Color(0xFFCC2936);     // Pressed state
static const Color brandRedLight = Color(0xFFFF6B6B);    // Highlights

// Secondary accent (used for success/positive states)
static const Color accentGreen = Color(0xFF06D6A0);      // Break completed, exercises done
static const Color accentGreenDark = Color(0xFF05B88A);

// Tertiary accent (informational)
static const Color accentBlue = Color(0xFF118AB2);        // Charts, links
static const Color accentBlueDark = Color(0xFF0D7A9F);

// Warning/Override
static const Color accentAmber = Color(0xFFFFC857);       // Override tokens, warnings
static const Color accentAmberDark = Color(0xFFE6B44E);
```

### 3.2 Dark Theme Palette

```dart
// Backgrounds (layered from deepest to shallowest)
static const Color darkBg0 = Color(0xFF09090B);          // Scaffold background
static const Color darkBg1 = Color(0xFF111113);          // Card backgrounds
static const Color darkBg2 = Color(0xFF1A1A1E);          // Elevated cards, modals
static const Color darkBg3 = Color(0xFF232328);          // Input fields, dropdown bg

// Text hierarchy
static const Color darkTextPrimary = Color(0xFFF4F4F5);  // Headings, primary content
static const Color darkTextSecondary = Color(0xFFA1A1AA); // Labels, descriptions
static const Color darkTextTertiary = Color(0xFF71717A);  // Timestamps, placeholders
static const Color darkTextDisabled = Color(0xFF52525B);  // Disabled states

// Borders & Dividers
static const Color darkBorder = Color(0xFF27272A);        // Card borders
static const Color darkDivider = Color(0xFF1F1F23);       // Section dividers
static const Color darkBorderFocused = Color(0xFFE63946); // Focused inputs

// Glassmorphism overlay
static const Color darkGlass = Color(0x1AFFFFFF);         // 10% white overlay for glass effect
static const Color darkGlassStroke = Color(0x33FFFFFF);   // 20% white for glass borders
```

### 3.3 Light Theme Palette

```dart
// Backgrounds
static const Color lightBg0 = Color(0xFFF8F9FA);         // Scaffold background
static const Color lightBg1 = Color(0xFFFFFFFF);          // Card backgrounds
static const Color lightBg2 = Color(0xFFF1F3F5);          // Elevated cards
static const Color lightBg3 = Color(0xFFE9ECEF);          // Input fields

// Text hierarchy
static const Color lightTextPrimary = Color(0xFF1A1A2E);  // Headings
static const Color lightTextSecondary = Color(0xFF6C757D); // Labels
static const Color lightTextTertiary = Color(0xFFADB5BD);  // Timestamps
static const Color lightTextDisabled = Color(0xFFCED4DA);  // Disabled

// Borders & Dividers
static const Color lightBorder = Color(0xFFE9ECEF);
static const Color lightDivider = Color(0xFFF1F3F5);
static const Color lightBorderFocused = Color(0xFFE63946);
```

### 3.4 Semantic Colors

```dart
static const Color success = Color(0xFF06D6A0);           // Break completed, exercises done
static const Color successBg = Color(0x1A06D6A0);         // 10% opacity bg
static const Color warning = Color(0xFFFFC857);            // Near budget limit
static const Color warningBg = Color(0x1AFFC857);
static const Color error = Color(0xFFEF476F);              // Over budget, critical
static const Color errorBg = Color(0x1AEF476F);
static const Color info = Color(0xFF118AB2);               // Informational
static const Color infoBg = Color(0x1A118AB2);
```

### 3.5 Gradient Definitions

```dart
// Hero gradient for primary CTA buttons and progress arcs
static const LinearGradient brandGradient = LinearGradient(
  colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Background accent gradient (subtle, behind main content)
static const LinearGradient bgAccentGradient = LinearGradient(
  colors: [Color(0x0DE63946), Color(0x00E63946)], // 5% to 0%
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// Success gradient for completed states
static const LinearGradient successGradient = LinearGradient(
  colors: [Color(0xFF06D6A0), Color(0xFF04BF8A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Card shimmer gradient (for loading states)
static const LinearGradient shimmerGradient = LinearGradient(
  colors: [Color(0xFF1A1A1E), Color(0xFF232328), Color(0xFF1A1A1E)],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment(-1.0, -0.5),
  end: Alignment(1.0, 0.5),
);
```

---

## 4. Typography System

### 4.1 Font Family

**Primary:** `Inter` (Google Fonts — bundled locally for offline use)  
**Monospace:** `JetBrains Mono` (PIN display, timer countdowns)

### 4.2 Font Setup in `pubspec.yaml`

```yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
        weight: 400
      - asset: assets/fonts/Inter-Medium.ttf
        weight: 500
      - asset: assets/fonts/Inter-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Inter-Bold.ttf
        weight: 700
      - asset: assets/fonts/Inter-ExtraBold.ttf
        weight: 800
  - family: JetBrainsMono
    fonts:
      - asset: assets/fonts/JetBrainsMono-Regular.ttf
        weight: 400
      - asset: assets/fonts/JetBrainsMono-Bold.ttf
        weight: 700
```

### 4.3 Text Style Scale

| Token | Size | Weight | Letter Spacing | Line Height | Usage |
|---|---|---|---|---|---|
| `displayLarge` | 40px | 800 | -1.5px | 1.1 | Splash screen title only |
| `displayMedium` | 32px | 700 | -0.8px | 1.2 | Onboarding hero headlines |
| `headlineLarge` | 28px | 700 | -0.5px | 1.25 | Screen titles (Dashboard greeting) |
| `headlineMedium` | 24px | 700 | -0.4px | 1.3 | Section headers |
| `headlineSmall` | 20px | 600 | -0.3px | 1.35 | Card titles |
| `titleLarge` | 18px | 600 | -0.2px | 1.4 | List item primary text |
| `titleMedium` | 16px | 600 | -0.1px | 1.4 | Buttons, nav labels |
| `titleSmall` | 14px | 600 | 0px | 1.4 | Chip labels, action text |
| `bodyLarge` | 16px | 400 | 0px | 1.5 | Body text, descriptions |
| `bodyMedium` | 14px | 400 | 0.1px | 1.5 | Secondary descriptions |
| `bodySmall` | 12px | 400 | 0.2px | 1.4 | Captions, timestamps |
| `labelLarge` | 14px | 500 | 0.5px | 1.0 | Badge labels |
| `labelMedium` | 12px | 500 | 0.5px | 1.0 | Small badge labels |
| `labelSmall` | 11px | 500 | 0.5px | 1.0 | Overline text (e.g., "EZZE BREAK") |
| `mono` | 32px | 700 | 4px | 1.0 | PIN display, countdown timer |

---

## 5. Spacing & Layout Grid

### 5.1 Base Unit
**4px** base unit. All spacing is a multiple of 4.

### 5.2 Named Spacing Tokens

```dart
class Spacing {
  static const double xs = 4;    // Micro gaps
  static const double sm = 8;    // Between related elements
  static const double md = 12;   // Standard content gap
  static const double lg = 16;   // Between sections
  static const double xl = 20;   // Major section padding
  static const double xxl = 24;  // Screen edge padding
  static const double xxxl = 32; // Large separators
  static const double huge = 48; // Hero spacing
  static const double massive = 64; // Splash/onboarding only
}
```

### 5.3 Screen Padding
- **Horizontal screen padding:** `24px` (left/right)
- **Top padding:** `SafeArea + 16px`
- **Bottom padding:** `SafeArea + 24px` (above nav bar)
- **Card internal padding:** `16px` (standard) | `20px` (hero cards)
- **Between cards:** `12px`
- **Between sections:** `24px`

### 5.4 Border Radii

```dart
class Radii {
  static const double xs = 6;    // Small badges, chips
  static const double sm = 8;    // Input fields
  static const double md = 12;   // Standard cards
  static const double lg = 16;   // Hero cards, dialogs
  static const double xl = 20;   // Bottom sheets
  static const double xxl = 24;  // Onboarding cards
  static const double full = 999; // Circular (avatars, FAB)
}
```

---

## 6. Component Library

### 6.1 EzzeCard (Glassmorphic)

The primary container component. All cards use a subtle glassmorphic style in dark mode.

```
┌─────────────────────────────────────┐
│  ┌─ Glass overlay (1px stroke) ──┐  │
│  │                               │  │
│  │   Content area                │  │
│  │   padding: 16px               │  │
│  │                               │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Dark Mode:**
- Background: `darkBg1` with 5% white overlay (`darkGlass`)
- Border: `1px solid darkGlassStroke` (20% white)
- Border radius: `12px`
- Box shadow: `0 2px 8px rgba(0,0,0,0.3)` — very subtle depth
- No elevation (flat design with border)

**Light Mode:**
- Background: `lightBg1` (pure white)
- Border: `1px solid lightBorder`
- Border radius: `12px`
- Box shadow: `0 1px 4px rgba(0,0,0,0.05)`

**Variants:**
- `EzzeCard.elevated` — Uses `darkBg2` / `lightBg2` background (for modals, sheets)
- `EzzeCard.accent` — Has a subtle `brandGradient` at 5% opacity left border (for hero cards)
- `EzzeCard.status(color)` — Left border colored with semantic color (success/warning/error)

### 6.2 EzzeButton

**Primary (Filled):**
```
┌─────────────────────────────────┐
│     ●  Button Label             │  height: 52px
│     (icon optional)             │  radius: 12px
└─────────────────────────────────┘
```
- Background: `brandGradient` (gradient from `brandRed` to `brandRedLight`)
- Text: White, `titleMedium` weight 600
- Press state: Scale to 0.97 + darker overlay
- Disabled: 40% opacity, no gradient

**Secondary (Outlined):**
- Background: transparent
- Border: `1.5px solid darkBorder`
- Text: `darkTextPrimary` / `lightTextPrimary`
- Press state: Background fills to 5% white

**Tertiary (Text):**
- No border, no background
- Text: `brandRed` color
- Underline on press

**Danger:**
- Background: `error` color solid
- Text: White

### 6.3 StatusBadge

Small pill-shaped indicator for states.

```
╭──────────────╮
│  ● Active    │  height: 24px, radius: full
╰──────────────╯
```

**Variants:**
| Variant | Dot Color | Background | Text Color |
|---|---|---|---|
| `active` | `success` | `successBg` | `success` |
| `warning` | `warning` | `warningBg` | `warning` |
| `error` | `error` | `errorBg` | `error` |
| `neutral` | `darkTextTertiary` | `darkBg3` | `darkTextSecondary` |
| `info` | `info` | `infoBg` | `info` |

### 6.4 CircularUsageGauge

The hero widget for the dashboard showing total daily usage.

```
        ┌────────────────┐
       ╱   ╲             │
      │  2h 34m  │        │  Diameter: 180px
      │  of 4h   │        │  Stroke width: 10px
       ╲   ╱             │  Track: darkBg3
        └────────────────┘  Progress: brandGradient
                             Center: Time text (mono)
                             Subtitle: "of Xh" (bodySmall)
```

- **Animated arc** using `CustomPainter` with `SweepGradient`
- **Background track:** `darkBg3` at 30% opacity
- **Progress arc:** `brandGradient` when under budget, `error` when over
- **Center text:** Usage time in `mono` style, "of X hours" below in `bodySmall`
- **Animation:** Smooth arc growth on load (500ms spring curve)
- **Haptic:** Light buzz when arc passes 75%, 90%, and 100% thresholds

### 6.5 AppUsageRow

Individual app usage item in lists.

```
┌─────────────────────────────────────────────┐
│  [Icon]  App Name          ●  1h 23m / 2h  │
│  46px    Break every 20m   ═══════75%══     │
│                            38m remaining    │
└─────────────────────────────────────────────┘
```

- **App icon:** 46px rounded square (radius: 10px), decoded from base64
- **Name:** `titleLarge` weight 600
- **Usage text:** `bodySmall`, colored by state (normal/warning/error)
- **Progress bar:** Height 4px, rounded, with gradient fill matching state
- **Sub-info row:** Session limit info (left) + remaining time or override hint (right)
- **Right side:** Toggle switch for monitoring on/off
- **Tap target:** Entire card navigates to `RuleConfigScreen`
- **Long press:** Quick context menu (Edit Rules, Start Break, Override)

### 6.6 QuickActionChip

Horizontally scrollable action buttons.

```
╭─────────────────╮
│  +  Add App      │  height: 36px
╰─────────────────╯  radius: full (pill)
                     padding: 14px horizontal
```

- Background: `darkBg1` with glass stroke
- Icon: 16px, `brandRed` tint
- Text: `titleSmall`
- Press: Scale 0.95, background brightens

### 6.7 StatCard

Small metric display card.

```
┌─────────────────┐
│  Breaks Done     │  Icon top-right
│  5 / 8           │  Value: headlineSmall
│  ▾ 12% vs avg   │  Trend: bodySmall + icon
└─────────────────┘
```

### 6.8 BottomNavBar

Custom bottom navigation with animated indicator.

```
┌───────────────────────────────────────────────┐
│                                               │
│   🏠          📱          📊          👤      │
│  Home       My Apps    Insights    Profile     │
│                                               │
│  ═══ (sliding indicator under active tab) ═══ │
└───────────────────────────────────────────────┘
```

- **Height:** 64px + SafeArea bottom
- **Background:** `darkBg1` with glass effect + top border (`darkDivider`)
- **Active indicator:** `brandRed` pill, 32px wide, slides with animation
- **Active icon:** Filled variant, `brandRed` tint
- **Inactive icon:** Outlined variant, `darkTextTertiary`
- **Active label:** `brandRed`, `labelMedium` weight 600
- **Inactive label:** `darkTextTertiary`, `labelMedium` weight 400
- **Animation:** Slide indicator smoothly between tabs (300ms spring curve)
- **Haptic:** Light tap on each tab switch

### 6.9 PinInputField

Custom PIN entry with 8 individual cells.

```
┌─┐ ┌─┐ ┌─┐ ┌─┐   ┌─┐ ┌─┐ ┌─┐ ┌─┐
│3│ │7│ │_│ │_│   │_│ │_│ │_│ │_│
└─┘ └─┘ └─┘ └─┘   └─┘ └─┘ └─┘ └─┘
     filled  active    unfilled
```

- **Cell size:** 48px × 56px
- **Gap between cells:** 8px (12px between groups of 4)
- **Filled state:** `brandRed` bottom border, number visible in `mono` style
- **Active state:** Blinking cursor, `brandRed` border glow animation
- **Empty state:** `darkBorder` bottom border
- **Error state:** All cells shake horizontally (vibrate animation) + `error` color
- **Success state:** All cells glow `success` green + checkmark overlay
- **Keyboard:** System numeric keyboard, no decimal
- **Haptic:** Light buzz on each digit entry, error buzz on wrong PIN

### 6.10 CountdownTimer

Large circular timer for break enforcement.

```
        ╭──────────╮
       │            │
       │    4:23     │  Diameter: 200px
       │  remaining  │  Stroke: 12px
       │            │
        ╰──────────╯
```

- **Circular progress** (reverse—starts full, empties)
- **Arc color:** `accentGreen` gradient
- **Center time:** `mono` 40px
- **Label:** "remaining" in `bodySmall`
- **Pulse animation:** Gentle scale pulse every 30s
- **Final 30s:** Arc turns `warning`, then `error` at 10s
- **Completion:** Checkmark animation + confetti burst

### 6.11 ExerciseCard

Card for exercise selection and progress.

```
┌─────────────────────────────────────┐
│  🏋  Push-ups                       │
│      15 reps × 3 sets              │
│      [Start Exercise]              │
│      ═════════ 2/3 sets ═════════  │
└─────────────────────────────────────┘
```

- **Icon:** Exercise-specific emoji or Material icon
- **Name:** `titleLarge`
- **Description:** `bodyMedium`, `darkTextSecondary`
- **Progress:** Segmented progress bar (one segment per set)
- **CTA:** Primary button "Start Set" or "Complete" for last set

---

## 7. Iconography

### 7.1 Icon Style
- **Library:** Material Icons Rounded (`Icons.xxx_rounded`)
- **Size scale:** 16px (inline) | 20px (list items) | 24px (cards) | 28px (actions) | 48px (empty states)
- **Color:** Always follows semantic meaning or matches text hierarchy

### 7.2 Feature Icons Mapping

| Feature | Outlined | Filled (Active) |
|---|---|---|
| Dashboard / Home | `dashboard_outlined` | `dashboard_rounded` |
| My Apps | `apps_outlined` | `apps_rounded` |
| Insights / Analytics | `insights_outlined` | `insights_rounded` |
| Profile | `person_outline_rounded` | `person_rounded` |
| Add App | `add_rounded` | — |
| PIN | `pin_outlined` | `pin_rounded` |
| Settings | `settings_outlined` | `settings_rounded` |
| Exercise | `fitness_center_rounded` | `fitness_center` |
| Break Timer | `pause_circle_outline_rounded` | `pause_circle_rounded` |
| Override | `lock_open_rounded` | `lock_open` |
| Export / PDF | `picture_as_pdf_outlined` | `picture_as_pdf_rounded` |
| Usage Access | `data_usage_rounded` | — |
| Accessibility | `accessibility_new_rounded` | — |
| Overlay | `layers_rounded` | — |
| Notifications | `notifications_outlined` | `notifications_rounded` |
| Privacy / Shield | `shield_outlined` | `verified_user_rounded` |
| Warning | `warning_amber_rounded` | — |
| Success / Check | `check_circle_outline_rounded` | `check_circle_rounded` |
| Delete | `delete_outline_rounded` | — |
| Edit | `edit_outlined` | — |
| Calendar | `calendar_today_rounded` | — |
| Chart | `bar_chart_rounded` | — |
| Time | `access_time_rounded` | — |
| Dark Mode | `dark_mode_outlined` | `dark_mode_rounded` |
| Light Mode | `light_mode_outlined` | `light_mode_rounded` |

---

## 8. Animation & Motion System

### 8.1 Easing Curves

```dart
class EzzeMotion {
  // Primary spring curve for most transitions
  static const Curve standard = Curves.easeOutCubic;

  // Entrance animations (elements appearing)
  static const Curve enter = Curves.easeOutBack; // Slight overshoot

  // Exit animations (elements disappearing)
  static const Curve exit = Curves.easeInCubic;

  // Bouncy interactions (buttons, toggles)
  static const Curve bounce = Curves.elasticOut;

  // Progress bar fill
  static const Curve progress = Curves.easeInOutCubic;
}
```

### 8.2 Duration Scale

| Token | Duration | Usage |
|---|---|---|
| `instant` | 100ms | Haptic feedback delay |
| `fast` | 150ms | Microinteractions (toggle, badge) |
| `normal` | 250ms | Page transitions, card appearance |
| `slow` | 400ms | Complex animations (gauge fill, chart) |
| `dramatic` | 600ms | Hero transitions, completion celebrations |
| `glacial` | 1000ms | Confetti, celebration sequences |

### 8.3 Specific Animations

| Animation | Duration | Curve | Description |
|---|---|---|---|
| **Tab switch (NavBar)** | 300ms | `standard` | Sliding pill indicator |
| **Card entrance** | 250ms | `enter` | Scale 0.95→1.0 + fade 0→1 |
| **Progress bar fill** | 500ms | `progress` | From 0 to current value |
| **Gauge arc** | 600ms | `standard` | Sweeps from 0° to target |
| **Button press** | 100ms | `standard` | Scale 1.0→0.97→1.0 |
| **PIN digit entry** | 150ms | `bounce` | Scale 0.8→1.0 with bounce |
| **PIN error shake** | 400ms | — | Horizontal oscillation ±12px |
| **Timer pulse** | 2000ms | — | Scale 1.0→1.03→1.0 repeat |
| **Confetti burst** | 1500ms | — | Particle spray from center |
| **Page transition** | 300ms | `standard` | Shared axis (horizontal) |
| **Bottom sheet** | 350ms | `standard` | Slide up from bottom |
| **Dialog** | 200ms | `enter` | Scale 0.9→1.0 + fade |
| **Chip press** | 100ms | `standard` | Scale 0.95→1.0 |
| **FAB press** | 150ms | `bounce` | Scale 0.9→1.0 |
| **Staggered list** | 50ms offset | `enter` | Each item 50ms after previous |

### 8.4 Page Transitions

Use **Shared Axis transitions** (Material Motion) for navigation:
- **Between tabs:** Fade through (cross-fade between tab contents)
- **Push navigation:** Shared axis horizontal (slide left, new page from right)
- **Modal/dialog:** Fade + scale from center
- **Bottom sheet:** Slide up with drag-to-dismiss

---

## 9. Screen Specifications

---

### 9.1 Splash Screen

**Duration:** 1.5 seconds (minimum), extends if DB initialization pending.

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│         [App Logo]              │  96×96px, rounded 20px
│                                 │
│        EZZE BREAK               │  labelSmall, 3px letter spacing
│                                 │  brandRed color
│    Use mindfully. Move          │
│    regularly. Feel better.      │  bodyMedium, darkTextSecondary
│                                 │
│                                 │
│         ●●● (loading)           │  3 dots pulsing animation
│                                 │
└─────────────────────────────────┘
```

**Background:** `darkBg0` with subtle radial gradient of `brandRed` at 3% opacity from center.

**Animations:**
1. Logo fades in + scales from 0.8→1.0 (400ms, `enter`)
2. Brand name fades in after 200ms delay
3. Tagline fades in after 400ms delay
4. Loading dots pulse continuously
5. Exit: Everything fades out simultaneously (200ms)

**Implementation Notes:**
- Show native Android splash first (via `launch_background.xml`)
- Flutter splash replaces native immediately
- Pre-load database, check onboarding status, prefetch permissions

---

### 9.2 Onboarding Flow

**5-page horizontal PageView** with swipe + button navigation.

#### Page 1: Welcome

```
┌─────────────────────────────────┐
│  ●━━━━ ○ ○ ○ ○         [Skip]  │  Progress dots + Skip
│                                 │
│                                 │
│         [App Logo]              │  100×100px
│                                 │
│        EZZE BREAK               │  labelSmall, brandRed
│                                 │
│    Use mindfully.               │  displayMedium (32px)
│    Move regularly.              │  Staggered line reveal
│    Feel better.                 │  3 lines, 100ms delay each
│                                 │
│    A private, offline-first     │  bodyLarge
│    digital wellbeing companion. │  darkTextSecondary
│                                 │
│  ╔═══════════════════════════╗  │
│  ║     Get Started           ║  │  Primary button, full width
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

#### Page 2: How It Works

```
┌─────────────────────────────────┐
│  ○ ●━━━ ○ ○ ○          [Skip]  │
│                                 │
│  How Ezze Break Works           │  headlineMedium
│  Designed for genuine self-     │  bodyMedium, secondary
│  control without cloud...       │
│                                 │
│  ┌──────────────────────────┐   │
│  │ ⏱  Usage & Session Limits│   │  Feature cards with icons
│  │    Set daily budgets...   │   │  Staggered entrance
│  └──────────────────────────┘   │  50ms delay between cards
│  ┌──────────────────────────┐   │
│  │ 🏋 Active Physical Breaks│   │
│  │    Take refreshing...     │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 🔒 Daily 8-Digit PIN     │   │
│  │    A secure rolling...    │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 🛡 100% Offline & Private│   │
│  │    Zero accounts, zero... │   │
│  └──────────────────────────┘   │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║       Continue            ║  │
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

#### Page 3: Your Profile

```
┌─────────────────────────────────┐
│  ○ ○ ●━━ ○ ○           [Skip]  │
│                                 │
│  Your Profile                   │  headlineMedium
│  How should we greet you?       │  bodyMedium, secondary
│                                 │
│  ┌──────────────────────────┐   │
│  │ 👤  Display Name         │   │  Text field
│  │     [e.g. Alex, Sam    ] │   │  Hint text
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🔒 No email, password,  │   │  Info card
│  │    or internet required. │   │
│  │    Stored only locally.  │   │
│  └──────────────────────────┘   │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║       Continue            ║  │
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

#### Page 4: Permissions

```
┌─────────────────────────────────┐
│  ○ ○ ○ ●━ ○            [Skip]  │
│                                 │
│  Configure Monitoring           │  headlineMedium
│  Android requires explicit      │  bodyMedium
│  permissions to track usage.    │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 1. Usage Access    [Done]│   │  Each permission:
│  │    Allows calculating... │   │  Status badge: Done/Required
│  │    [Open Settings]       │   │  Open settings button if needed
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 2. Overlay         [Req] │   │
│  │    Allows presenting...  │   │
│  │    [Open Settings]       │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 3. Accessibility   [Req] │   │
│  │    Detects foreground... │   │
│  │    [Open Settings]       │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 4. Notifications   [Req] │   │
│  │    Sends gentle break... │   │
│  │    [Open Settings]       │   │
│  └──────────────────────────┘   │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║       Continue            ║  │
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

#### Page 5: Ready to Go

```
┌─────────────────────────────────┐
│  ○ ○ ○ ○ ●━                    │  No skip on final page
│                                 │
│                                 │
│         ✅                      │  Large success icon
│                                 │  56px, success color
│    You're Ready to Go!          │  headlineMedium
│                                 │
│    Add your most distracting    │  bodyLarge
│    apps, choose your daily      │  darkTextSecondary
│    budget, and enjoy healthy    │
│    screen time.                 │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🔑 8-Digit PIN            │   │  Summary info card
│  │    Auto-generated daily   │   │
│  │ ──────────────────────── │   │
│  │ 📴 Offline Guarantee      │   │
│  │    All data stays local   │   │
│  └──────────────────────────┘   │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║   Enter Ezze Break        ║  │  brandGradient button
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

---

### 9.3 Dashboard (Home)

The primary screen. Must be **glanceable**—all critical info above the fold.

```
┌─────────────────────────────────┐
│                                 │
│  [Logo] EZZE BREAK       🔑 👤 │  Header row
│         Hello, Alex             │  Greeting or "Mindful Dashboard"
│  Monday, October 20, 2026      │  Date subtitle
│                                 │
│  ⚠ Permissions Incomplete ─────│  Conditional warning banner
│    Usage access needed.  [Fix]  │  Only shows if perms missing
│                                 │
│  ┌───── Hero Usage Gauge ─────┐ │
│  │                            │ │
│  │    ╭──────────╮            │ │  CircularUsageGauge
│  │   │   2h 34m   │           │ │  Center: total usage (mono)
│  │   │   of 4h    │           │ │  Subtitle: total budget
│  │    ╰──────────╯            │ │  Arc: brandGradient
│  │                            │ │
│  │  Breaks   Exercises  Over  │ │  3 stat columns below gauge
│  │   5/8        3       1     │ │
│  └────────────────────────────┘ │
│                                 │
│  [+ Add] [🔑 PIN] [🏋 Exer.] [📄 PDF]│  Quick action chips
│                                 │
│  Monitored Applications  [+Add] │  Section header
│                                 │
│  ┌────────────────────────────┐ │
│  │ [📱] Instagram     ■ ON   │ │  App row with usage bar
│  │      45m of 2h             │ │
│  │      ═══════37%══════      │ │
│  │      Break/20m  1h15m left │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ [📱] TikTok       ■ ON   │ │
│  │      1h of 1h              │ │
│  │      ═══════100%═════ ⚠   │ │  Red when over budget
│  │      Break/15m  OVER       │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ [📱] YouTube       ■ OFF  │ │
│  │      12m of 3h             │ │
│  │      ═══════7%═══════      │ │
│  │      Break/30m  2h48m left │ │
│  └────────────────────────────┘ │
│                                 │
│──────────────────────────────── │
│  🏠       📱       📊       👤 │  Bottom nav
│  Home   My Apps  Insights  Prof │
│  ═══                            │  Active indicator under Home
└─────────────────────────────────┘
```

**Key Design Decisions:**
1. **Circular gauge replaces the rectangular card** for total usage—more visually impactful
2. **Quick stats** (breaks, exercises, overrides) are inside the gauge card, not separate
3. **Quick action chips** are horizontally scrollable pills
4. **App list** uses `AppUsageRow` component with inline progress bars
5. **Pull-to-refresh** syncs all data from native Android
6. **Empty state** shows large illustration + "Add First App" CTA when no apps monitored

**Empty State:**
```
┌────────────────────────────────┐
│                                │
│         📱                     │  Large icon or illustration
│                                │  48px, accent color on 12% bg
│   Start Monitoring             │  headlineSmall
│   Your Habits                  │
│                                │
│   Choose the apps you spend    │  bodyMedium
│   the most time on...          │  darkTextSecondary
│                                │
│   [+ Add First Monitored App]  │  Primary button
│                                │
└────────────────────────────────┘
```

---

### 9.4 My Apps (App Management)

Tab 2 in bottom nav. Full list of all monitored apps with management capabilities.

```
┌─────────────────────────────────┐
│                                 │
│  My Apps                        │  AppBar title
│                       [Search]  │  Search icon button
│                                 │
│  ┌──── Filter Chips ──────────┐ │
│  │ [All] [Active] [Paused]    │ │  Segmented control
│  └────────────────────────────┘ │
│                                 │
│  Active Monitoring (3)          │  Section header
│                                 │
│  ┌────────────────────────────┐ │
│  │ [📱] Instagram     ■ ON   │ │
│  │      Budget: 2h • Break/20m│ │
│  │      Today: 45m used       │ │
│  │      ═══════37%══════      │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ [📱] TikTok       ■ ON   │ │
│  │      Budget: 1h • Break/15m│ │
│  │      Today: 1h used   ⚠   │ │
│  │      ═══════100%═════      │ │
│  └────────────────────────────┘ │
│                                 │
│  Paused (1)                     │  Section header
│                                 │
│  ┌────────────────────────────┐ │
│  │ [📱] YouTube      ■ OFF   │ │
│  │      Budget: 3h • Break/30m│ │
│  │      Monitoring paused     │ │
│  └────────────────────────────┘ │
│                                 │
│         [+ Add App]    (FAB)    │  Floating action button
│──────────────────────────────── │
│  🏠       📱       📊       👤 │
│         My Apps                 │
│          ═══                    │
└─────────────────────────────────┘
```

**Interactions:**
- **Tap app card** → Navigate to `RuleConfigScreen` for that app
- **Swipe left** → Reveal "Remove" action (red delete button)
- **Toggle switch** → Enable/disable monitoring instantly
- **Search** → Filter apps by name (real-time, debounced 300ms)
- **Filter chips** → Show All / Active only / Paused only

---

### 9.5 App Selector Bottom Sheet

Modal bottom sheet for adding new apps to monitor.

```
┌─────────────────────────────────┐
│  ▬▬▬ (drag handle)              │  6px × 40px, rounded
│                                 │
│  Add Applications               │  headlineSmall
│  Select apps to monitor         │  bodySmall, secondary
│                                 │
│  🔍 Search installed apps...    │  Search field
│                                 │
│  ┌────────────────────────────┐ │
│  │ [📱] Instagram      [✓]   │ │  Already monitored: checkmark
│  │ [📱] TikTok         [✓]   │ │  
│  │ [📱] Twitter        [+]   │ │  Unmonitored: add button
│  │ [📱] Reddit         [+]   │ │
│  │ [📱] YouTube        [✓]   │ │
│  │ [📱] Chrome         [+]   │ │
│  │ [📱] Facebook       [+]   │ │
│  │ [📱] Snapchat       [+]   │ │
│  └────────────────────────────┘ │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  Done (3 selected)        ║  │  Primary button
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

**Sheet Behavior:**
- **Initial height:** 70% screen height
- **Max height:** 90% screen height (expandable by drag)
- **Background:** `darkBg2` (elevated)
- **Scrim:** 50% black overlay on parent
- **Corner radius:** `xl` (20px) top corners only
- **Drag handle:** `darkBorder` colored pill
- **Search:** Auto-focus on open, filter installed apps in real-time
- **App list:** Shows all user-installed apps (excludes system apps)
- **Already monitored:** Shown with checkmark, tappable to remove
- **New selection:** Tap to toggle selection, shows green checkmark

---

### 9.6 Rule Configuration Screen

Full-page screen for configuring an individual app's monitoring rules.

```
┌─────────────────────────────────┐
│  ←  App Rules                   │  AppBar with back button
│                       [Delete]  │  Delete app action
│                                 │
│  ┌────────────────────────────┐ │
│  │ [📱 Large]  Instagram      │ │  Hero card with app info
│  │  64px       com.instagram.a│ │  Package name in bodySmall
│  │             Status: ● Active│ │  StatusBadge
│  └────────────────────────────┘ │
│                                 │
│  Daily Screen Budget            │  Section title
│  ┌────────────────────────────┐ │
│  │  ◄───────● 2h ──────────► │ │  Slider: 15m to 8h
│  │  Min: 15m          Max: 8h │ │  Step: 15m
│  │                            │ │
│  │  Common presets:            │ │
│  │  [30m] [1h] [2h] [4h]     │ │  Quick-select chips
│  └────────────────────────────┘ │
│                                 │
│  Session Limit                  │  Section title
│  ┌────────────────────────────┐ │
│  │  ◄───────● 20m ─────────► │ │  Slider: 5m to 60m
│  │  Min: 5m           Max: 60m│ │  Step: 5m
│  │                            │ │
│  │  Presets: [10m] [15m] [20m]│ │
│  │           [30m] [45m] [60m]│ │
│  └────────────────────────────┘ │
│                                 │
│  Break Duration                 │  Section title
│  ┌────────────────────────────┐ │
│  │  ◄───────● 5m ──────────► │ │  Slider: 2m to 15m
│  │  Min: 2m           Max: 15m│ │  Step: 1m
│  │                            │ │
│  │  Presets: [3m] [5m] [10m]  │ │
│  └────────────────────────────┘ │
│                                 │
│  Today's Usage Summary          │  Section title
│  ┌────────────────────────────┐ │
│  │  Used:     45m              │ │
│  │  Budget:   2h               │ │
│  │  Sessions: 3                │ │
│  │  Breaks:   2 (1 completed)  │ │
│  │  Overrides: 0               │ │
│  └────────────────────────────┘ │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║      Save Changes         ║  │  Primary button
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

**Slider Design:**
- **Track:** 4px height, `darkBg3` background, `brandGradient` fill
- **Thumb:** 20px circle, white with shadow, `brandRed` center dot
- **Label:** Shows current value above thumb (tooltip style)
- **Haptic:** Light tick at each step position
- **Preset chips:** `QuickActionChip` style, outlined, tap fills with `brandRed`

---

### 9.7 Insights (Analytics)

Tab 3 in bottom nav. Data visualization and usage analytics.

```
┌─────────────────────────────────┐
│                                 │
│  Insights                       │  AppBar title
│                     [📄 Export] │  Export button
│                                 │
│  ┌──── Period Selector ───────┐ │
│  │ [Today] [Yesterday] [7Day] │ │  Segmented control
│  └────────────────────────────┘ │
│                                 │
│  ┌────── Summary Card ────────┐ │
│  │  Total Usage:    3h 42m    │ │  Accent stat card
│  │  Avg Daily:      2h 15m    │ │
│  │  Breaks Done:    12/18     │ │
│  │  Exercises:      8         │ │
│  │  Overrides:      2         │ │
│  └────────────────────────────┘ │
│                                 │
│  7-Day Usage Trend              │  Section title
│  ┌────────────────────────────┐ │
│  │       ┃                    │ │  Bar chart
│  │   ┃   ┃       ┃           │ │  fl_chart BarChart
│  │   ┃   ┃   ┃   ┃   ┃      │ │  Gradient bars
│  │   ┃   ┃   ┃   ┃   ┃   ┃  │ │  X: Weekday labels
│  │  Mon Tue Wed Thu Fri Sat  │ │  Y: Hours
│  └────────────────────────────┘ │
│                                 │
│  Per-App Breakdown              │  Section title
│  ┌────────────────────────────┐ │
│  │ [Pie Chart]                │ │  Donut chart
│  │                            │ │  Center: total time
│  │ Instagram  45m ═════       │ │  Legend below
│  │ TikTok     1h  ════════   │ │  Sorted by usage
│  │ YouTube    12m ══          │ │  Color-coded segments
│  └────────────────────────────┘ │
│                                 │
│  Break Compliance               │  Section title
│  ┌────────────────────────────┐ │
│  │  Compliance Rate: 67%      │ │
│  │  ═══════════67%════════    │ │  Green if >70%, amber if >50%
│  │  12 of 18 breaks completed │ │  Red if <50%
│  └────────────────────────────┘ │
│                                 │
│──────────────────────────────── │
│  🏠       📱       📊       👤 │
│                  Insights       │
│                   ═══           │
└─────────────────────────────────┘
```

**Chart Specifications:**

**7-Day Bar Chart:**
- Bar width: 28px
- Bar radius: 6px top
- Bar gradient: `brandGradient` (vertical)
- Background grid: `darkDivider` horizontal lines
- X-axis labels: Weekday abbreviations (Mon, Tue, etc.)
- Y-axis labels: Hours (0h, 1h, 2h, etc.)
- Today's bar: Slight glow effect (shadow with `brandRed` at 20% opacity)
- Animation: Bars grow from bottom (staggered, 50ms between bars)
- Touch: Tap a bar to show tooltip with exact time

**Donut Chart:**
- Outer radius: 80px
- Inner radius: 55px (35px ring)
- Segment gap: 3px
- Center text: Total time (mono)
- Colors: Rotate through [brandRed, accentBlue, accentGreen, accentAmber, #8B5CF6, #EC4899]
- Animation: Segments sweep in from 0° (600ms, staggered)
- Touch: Tap segment to highlight + show tooltip

---

### 9.8 Break Enforcement Screen

Full-screen, immersive break experience. This is the screen shown when a session limit is reached.

```
┌─────────────────────────────────┐
│                                 │
│  ⏸  Break Time                 │  AppBar, no back button
│     for Instagram               │  App name subtitle
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │
│  │     ╭──────────────╮       │ │
│  │    │                │      │ │  Large countdown timer
│  │    │     4:23        │      │ │  200px diameter
│  │    │   remaining     │      │ │  12px stroke
│  │     ╰──────────────╯       │ │  accentGreen arc
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  Complete an exercise to earn   │  bodyMedium
│  credit toward this break.      │  darkTextSecondary
│                                 │
│  Available Exercises            │  Section title
│  ┌────────────────────────────┐ │
│  │ 🏋 Push-ups               │ │  Exercise cards
│  │   15 reps × 3 sets         │ │  Tap to start
│  │   [Start Exercise]         │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ 🦵 Squats                  │ │
│  │   20 reps × 2 sets         │ │
│  │   [Start Exercise]         │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ 🧘 Stretching              │ │
│  │   Hold 30s × 4 sets        │ │
│  │   [Start Exercise]         │ │
│  └────────────────────────────┘ │
│                                 │
│  ──── or enter PIN to resume ──│  Divider with text
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  🔑 Enter 8-Digit PIN     ║  │  Secondary button
│  ╚═══════════════════════════╝  │  Opens PIN entry
│                                 │
└─────────────────────────────────┘
```

**Behavior:**
- **Non-dismissible:** No back button, no swipe back. Must complete break or enter PIN.
- **Timer:** Counts down from break duration (default 5m). Arc empties as time passes.
- **Exercise credit:** Completing any exercise counts toward break completion.
- **Timer auto-completes:** When timer reaches 0, break is marked complete automatically.
- **PIN bypass:** Entering correct PIN immediately ends the break and allows resume.
- **Confetti:** On timer completion, show confetti burst + success screen for 2s.

**Completion Screen (2s):**
```
┌─────────────────────────────────┐
│                                 │
│         ✅                      │  Large check animation
│                                 │
│    Break Complete!              │  headlineMedium
│                                 │
│    You did 15 push-ups          │  bodyLarge
│    and rested for 5 minutes.    │  Summary text
│                                 │
│    Keep up the great work!      │  bodyMedium, success color
│                                 │
│  🎊 (confetti particles) 🎊    │  Animated confetti
│                                 │
└─────────────────────────────────┘
```

---

### 9.9 Exercise Session Screen

Full-screen exercise execution with timer and rep counter.

```
┌─────────────────────────────────┐
│  ←  Exercise                    │  AppBar with back
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │
│  │  🏋                        │ │  Large exercise icon
│  │  Push-ups                  │ │  headlineMedium
│  │                            │ │
│  │  Set 2 of 3                │ │  Progress label
│  │  ●●○                       │ │  Dot indicators
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │
│  │     ╭──────────╮           │ │
│  │    │    0:42    │          │ │  Per-set timer
│  │    │  elapsed   │          │ │  Counts up
│  │     ╰──────────╯           │ │  140px diameter
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  15 reps per set                │  bodyLarge
│  Take your time, focus on form. │  bodyMedium, secondary
│                                 │
│  ╔═══════════════════════════╗  │
│  ║   ✓  Complete Set 2       ║  │  Primary button
│  ╚═══════════════════════════╝  │  Tap to advance
│                                 │
│  ╔═══════════════════════════╗  │
│  ║     Skip Exercise         ║  │  Secondary button
│  ╚═══════════════════════════╝  │  Outlined
│                                 │
└─────────────────────────────────┘
```

---

### 9.10 Exercise Library

Accessible from Profile and Quick Actions. Manage exercise presets and view history.

```
┌─────────────────────────────────┐
│  ←  Exercise Library            │  AppBar
│                       [+ Add]   │  Add custom exercise
│                                 │
│  ┌─ Tab Bar ──────────────────┐ │
│  │ [Exercises]    [History]   │ │  Two tabs
│  └────────────────────────────┘ │
│                                 │
│  ===== Exercises Tab =====      │
│                                 │
│  ┌────────────────────────────┐ │
│  │ 🏋 Push-ups               │ │
│  │   15 reps × 3 sets         │ │
│  │   Upper body               │ │  Category tag
│  │                     [Edit] │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ 🦵 Squats                  │ │
│  │   20 reps × 2 sets         │ │
│  │   Lower body               │ │
│  │                     [Edit] │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ 🧘 Stretching              │ │
│  │   30s hold × 4 sets        │ │
│  │   Flexibility              │ │
│  │                     [Edit] │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ 🏃 Jumping Jacks           │ │
│  │   25 reps × 2 sets         │ │
│  │   Cardio                   │ │
│  │                     [Edit] │ │
│  └────────────────────────────┘ │
│                                 │
│  ===== History Tab =====        │
│                                 │
│  Today                          │  Date grouping
│  ┌────────────────────────────┐ │
│  │ 🏋 Push-ups    15 reps     │ │
│  │   10:30 AM     3 sets done │ │
│  └────────────────────────────┘ │
│                                 │
│  Yesterday                      │
│  ┌────────────────────────────┐ │
│  │ 🦵 Squats     20 reps     │ │
│  │   2:15 PM     2 sets done  │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Add/Edit Exercise Dialog:**
```
┌─────────────────────────────────┐
│  Add Exercise                   │
│                                 │
│  Exercise Name                  │
│  ┌────────────────────────────┐ │
│  │ [Enter exercise name     ] │ │
│  └────────────────────────────┘ │
│                                 │
│  Reps per Set                   │
│  ┌────────────────────────────┐ │
│  │ [15                      ] │ │
│  └────────────────────────────┘ │
│                                 │
│  Number of Sets                 │
│  ┌────────────────────────────┐ │
│  │ [3                       ] │ │
│  └────────────────────────────┘ │
│                                 │
│  Duration per Set (seconds)     │
│  ┌────────────────────────────┐ │
│  │ [0 (rep-based)           ] │ │
│  └────────────────────────────┘ │
│                                 │
│  [Cancel]            [Save]     │
│                                 │
└─────────────────────────────────┘
```

---

### 9.11 Override Dialog

Modal dialog for temporarily bypassing an app's daily budget limit.

```
┌─────────────────────────────────┐
│                                 │
│  🔓 Override Instagram          │  Dialog title
│                                 │
│  Current Usage:   2h 15m        │
│  Daily Budget:    2h            │
│  Over Budget By:  15m           │  Red text
│                                 │
│  Override Duration:             │
│  ┌────────────────────────────┐ │
│  │ [15m] [30m] [1h] [Custom] │ │  Duration chips
│  └────────────────────────────┘ │
│                                 │
│  ⚠ Overriding requires your    │  Warning text
│    8-digit PIN.                 │  bodySmall, warning color
│                                 │
│  [Cancel]     [Enter PIN →]     │  Buttons
│                                 │
└─────────────────────────────────┘
```

**Flow:**
1. User taps "Limit Over • Tap to Override" on dashboard app card
2. Override dialog appears with usage summary
3. User selects override duration
4. User taps "Enter PIN →" which pushes `PinEntryScreen`
5. On correct PIN, override is logged and app restriction is temporarily lifted
6. Dialog closes with success snackbar

---

### 9.12 PIN Entry Screen

Full-screen PIN entry with custom number pad.

```
┌─────────────────────────────────┐
│  ←                              │  Back button only
│                                 │
│                                 │
│  Enter 8-Digit PIN              │  headlineMedium
│                                 │
│  Your daily PIN changes every   │  bodyMedium
│  24 hours for mindful friction. │  darkTextSecondary
│                                 │
│  ┌─┐ ┌─┐ ┌─┐ ┌─┐  ┌─┐ ┌─┐ ┌─┐ ┌─┐│  PIN cells (8)
│  │3│ │7│ │ │ │ │  │ │ │ │ │ │ │ ││  Grouped 4-4
│  └─┘ └─┘ └─┘ └─┘  └─┘ └─┘ └─┘ └─┘│
│                                 │
│  [Error message if wrong PIN]   │  Red text, shake animation
│                                 │
│                                 │
│  ┌─────┬─────┬─────┐           │  Custom number pad
│  │  1  │  2  │  3  │           │  (Material style)
│  ├─────┼─────┼─────┤           │  Button size: 72×56px
│  │  4  │  5  │  6  │           │  Ripple on tap
│  ├─────┼─────┼─────┤           │  Haptic on each tap
│  │  7  │  8  │  9  │           │
│  ├─────┼─────┼─────┤           │
│  │     │  0  │  ⌫  │           │  Backspace button
│  └─────┴─────┴─────┘           │
│                                 │
└─────────────────────────────────┘
```

**Alternative: Use system keyboard** if custom number pad is not preferred. The system numeric keyboard works well and is simpler to implement.

**Behavior:**
- Auto-validates when 8 digits are entered (no submit button needed)
- On wrong PIN: Cells shake horizontally (400ms), turn red briefly, then clear
- On correct PIN: Cells turn green, checkmark animation, auto-navigate back with result
- Max attempts: No limit (it's self-imposed friction, not security)

---

### 9.13 Show PIN Screen

Screen to display the current day's PIN for reference.

```
┌─────────────────────────────────┐
│  ←  Your Daily PIN              │  AppBar
│                                 │
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │  Hero card
│  │  Today's 8-Digit PIN      │ │  bodyMedium
│  │                            │ │
│  │  3 7 4 2  8 1 6 5          │ │  Mono, 32px, spaced
│  │                            │ │  brandRed color
│  │  Valid until midnight      │ │  bodySmall
│  │  (23h 42m remaining)       │ │  Countdown
│  │                            │ │
│  │  [Copy to Clipboard]       │ │  Text button
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌────────────────────────────┐ │
│  │  How the PIN works         │ │  Info card
│  │                            │ │
│  │  • Generated deterministic │ │
│  │    from date + device ID   │ │
│  │  • Changes at midnight     │ │
│  │  • No internet required    │ │
│  │  • Cannot be predicted     │ │
│  │    without this screen     │ │
│  └────────────────────────────┘ │
│                                 │
│  💡 Write it on a sticky note  │  Tip callout
│     and place it away from     │  bodySmall
│     your usual phone spot.     │  accentAmber tint
│                                 │
└─────────────────────────────────┘
```

---

### 9.14 Profile Screen

Tab 4 in bottom nav. User profile, quick navigation hub, and app info.

```
┌─────────────────────────────────┐
│                                 │
│  Profile                    ⚙  │  AppBar + Settings gear
│                                 │
│  ┌────────────────────────────┐ │
│  │  ╭───╮                    │ │  Avatar circle
│  │  │ A │   Alex             │ │  First letter of name
│  │  ╰───╯   Offline Profile  │ │  58px circle
│  │           58px       [✏] │ │  accent bg at 15%
│  └────────────────────────────┘ │
│                                 │
│  ┌───────────┬───────────────┐ │  Two stat cards side by side
│  │Usage Today│ Monitored Apps│ │
│  │  2h 34m   │   3 active    │ │
│  └───────────┴───────────────┘ │
│                                 │
│  ┌────────────────────────────┐ │  Quick nav menu card
│  │ 🔑 Daily 8-Digit PIN    ▸ │ │
│  │    View current PIN        │ │
│  │ ────────────────────────── │ │
│  │ 🏋 Exercise Library      ▸ │ │
│  │    Manage exercises        │ │
│  │ ────────────────────────── │ │
│  │ 📄 Export PDF Reports    ▸ │ │
│  │    Generate reports        │ │
│  │ ────────────────────────── │ │
│  │ ⚙ System Settings       ▸ │ │
│  │    Themes, permissions     │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌────────────────────────────┐ │  Privacy card
│  │ ✅ 100% Offline & Private │ │
│  │    No internet, no         │ │
│  │    telemetry, no accounts. │ │
│  └────────────────────────────┘ │
│                                 │
│  [Logo] Ezze Break v1.0.0      │  Footer
│  Use mindfully. Move regularly. │
│                                 │
│──────────────────────────────── │
│  🏠       📱       📊       👤 │
│                            Prof │
│                             ═══ │
└─────────────────────────────────┘
```

---

### 9.15 Settings Screen

Accessed from Profile gear icon. System configuration.

```
┌─────────────────────────────────┐
│  ←  Settings                    │  AppBar
│                                 │
│  Appearance                     │  Section header
│  ┌────────────────────────────┐ │
│  │ 🌙 Theme                   │ │
│  │   ┌──────────────────────┐ │ │  Segmented control
│  │   │[System][Light][Dark] │ │ │  3 options
│  │   └──────────────────────┘ │ │
│  └────────────────────────────┘ │
│                                 │
│  Monitoring                     │  Section header
│  ┌────────────────────────────┐ │
│  │ 📊 Global Monitoring  ■ ON│ │  Master toggle
│  │    Enable/disable all      │ │
│  │    monitoring               │ │
│  └────────────────────────────┘ │
│                                 │
│  Permissions                    │  Section header
│  ┌────────────────────────────┐ │
│  │ 📱 Usage Access    [Done] │ │  Permission rows
│  │ 🔲 Display Overlay  [Done]│ │  StatusBadge per permission
│  │ ♿ Accessibility    [Req] │ │  Tap to open settings
│  │ 🔔 Notifications   [Done]│ │
│  └────────────────────────────┘ │
│                                 │
│  Data Management                │  Section header
│  ┌────────────────────────────┐ │
│  │ 🗑 Clear History           │ │  Danger zone
│  │   Delete usage and break   │ │
│  │   records. Keep rules.     │ │
│  │ ────────────────────────── │ │
│  │ ⚠ Reset All Data           │ │  Red text
│  │   Erase everything and    │ │
│  │   restart from scratch.    │ │
│  └────────────────────────────┘ │
│                                 │
│  About                          │  Section header
│  ┌────────────────────────────┐ │
│  │ Version: 1.0.0             │ │
│  │ Package: com.ezze.break    │ │
│  │ Database: ezze_break.db    │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

---

### 9.16 Reports / Export Screen

PDF report generation and preview.

```
┌─────────────────────────────────┐
│  ←  Export Reports              │  AppBar
│                                 │
│  Generate PDF Reports           │  headlineSmall
│  Create downloadable wellbeing  │  bodyMedium
│  reports with usage data.       │
│                                 │
│  Report Type                    │  Section title
│  ┌────────────────────────────┐ │
│  │ [Today's Report]           │ │  Radio-style selection
│  │ [7-Day Summary Report]    │ │  Card selection
│  └────────────────────────────┘ │
│                                 │
│  Report Contents                │  Section title
│  ┌────────────────────────────┐ │
│  │ ✓ Total usage summary     │ │  Checklist of contents
│  │ ✓ Per-app breakdown       │ │
│  │ ✓ Break compliance stats  │ │
│  │ ✓ Exercise activity log   │ │
│  │ ✓ Override history        │ │
│  └────────────────────────────┘ │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  📄 Generate & Download   ║  │  Primary button
│  ╚═══════════════════════════╝  │
│                                 │
│  ┌────────────────────────────┐ │
│  │ ✅ Last exported:          │ │  Success card (after export)
│  │    /Downloads/EzzeBreak... │ │
│  │    [Open File] [Share]     │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

---

### 9.17 Native Restriction Overlay (Kotlin)

The Android native overlay that appears when a monitored app's session limit is reached. This is a Kotlin `Activity` (`RestrictionActivity`) launched via the `AccessibilityService`.

```
┌─────────────────────────────────┐
│                                 │  Full-screen overlay
│                                 │  Semi-transparent background
│                                 │
│  ┌────────────────────────────┐ │
│  │                            │ │  Centered card
│  │   ⏸  Time for a Break     │ │  Title
│  │                            │ │
│  │   You've been using        │ │  Message
│  │   Instagram for 20 minutes │ │
│  │   continuously.            │ │
│  │                            │ │
│  │   Take a mindful break     │ │
│  │   with some exercise.      │ │
│  │                            │ │
│  │  ╔════════════════════╗    │ │
│  │  ║  Start Break       ║    │ │  Primary CTA
│  │  ╚════════════════════╝    │ │  Opens Flutter break screen
│  │                            │ │
│  │  ╔════════════════════╗    │ │
│  │  ║  Override (PIN)    ║    │ │  Secondary CTA
│  │  ╚════════════════════╝    │ │  Opens Flutter override flow
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Native Overlay Design:**
- Background: 80% black overlay covering entire screen
- Card: White (light) or `darkBg2` (dark), centered, 90% width, rounded 20px
- Brand colors matching Flutter theme
- Two CTAs: "Start Break" (green, primary) and "Override (PIN)" (outlined)
- Non-dismissible (no back press, no outside tap)

---

## 10. Navigation Architecture

### 10.1 Navigation Tree

```
EzzeBreakApp
├── OnboardingFlow (PageView, 5 pages)
│   └── → MainNavigationLayout (on completion)
│
└── MainNavigationLayout
    ├── BottomNavBar
    │   ├── Tab 0: DashboardScreen (Home)
    │   ├── Tab 1: AppListScreen (My Apps)
    │   ├── Tab 2: AnalyticsScreen (Insights)
    │   └── Tab 3: ProfileScreen (Profile)
    │
    ├── Push Navigation (from any tab):
    │   ├── RuleConfigScreen (app rule editing)
    │   ├── BreakScreen (break enforcement - non-dismissible)
    │   │   └── ExerciseSessionScreen (exercise execution)
    │   ├── ShowPinScreen (view daily PIN)
    │   ├── PinEntryScreen (enter PIN for validation)
    │   ├── ExerciseLibraryScreen (manage exercises)
    │   ├── ReportsScreen (export PDFs)
    │   └── SettingsScreen (app settings)
    │
    ├── Modal Overlays:
    │   ├── AppSelectorSheet (bottom sheet)
    │   ├── OverrideDialog (alert dialog)
    │   ├── EditNameDialog (alert dialog)
    │   ├── ClearHistoryDialog (alert dialog)
    │   └── ResetAllDialog (alert dialog)
    │
    └── FAB:
        └── AppSelectorSheet (on tap, tabs 0 & 1)
```

### 10.2 Navigation Patterns

| Navigation Type | Implementation |
|---|---|
| Tab switching | `IndexedStack` (preserves state) + `BottomNavigationBar` |
| Push to detail | `Navigator.push()` with `MaterialPageRoute` |
| Bottom sheet | `showModalBottomSheet()` with transparent bg |
| Dialog | `showDialog()` with `AlertDialog` |
| Break screen | `Navigator.push()` with `WillPopScope` (non-dismissible) |

---

## 11. State Management Patterns

### 11.1 Provider Architecture (Riverpod 2.x)

```
Providers
├── Theme & Preferences
│   ├── themeModeProvider (StateNotifierProvider)
│   ├── onboardingCompletedProvider (StateNotifierProvider)
│   └── profileNameProvider (StateNotifierProvider)
│
├── Data Layer
│   ├── databaseProvider (Provider<AppDatabase>)
│   ├── breakServiceProvider (Provider<BreakService>)
│   └── pinServiceProvider (Provider<PinService>)
│
├── Monitoring
│   ├── monitoredAppsListProvider (StateNotifierProvider<List<MonitoredApp>>)
│   ├── appRulesMapProvider (StateNotifierProvider<Map<String, AppRule>>)
│   ├── todayUsageProvider (StateNotifierProvider<Map<String, DailyUsage>>)
│   ├── permissionsProvider (StateNotifierProvider<PermissionState>)
│   └── usageMonitorServiceProvider (Provider<UsageMonitorService>)
│
└── Analytics
    └── analyticsSummaryProvider (FutureProvider<AnalyticsSummary>)
```

### 11.2 Data Flow

```
Native Android (Kotlin)
    │ MethodChannel
    ▼
NativeAppService (static methods)
    │
    ▼
UsageMonitorService ──► AppDatabase (sqflite)
    │                        │
    ▼                        ▼
Riverpod Providers ──► UI Widgets (ConsumerWidget/ConsumerStatefulWidget)
```

---

## 12. Accessibility

### 12.1 Requirements

| Feature | Implementation |
|---|---|
| **Semantic labels** | All icons and interactive elements have `Tooltip` or `Semantics` |
| **Touch targets** | Minimum 48×48px for all interactive elements |
| **Color contrast** | WCAG AA compliant (4.5:1 for text, 3:1 for large text) |
| **Screen reader** | Full `Semantics` tree for all screens |
| **Text scaling** | Supports system text scaling up to 200% without layout break |
| **Reduced motion** | Respect `MediaQuery.disableAnimations` |
| **Focus management** | Logical tab order, auto-focus on key inputs |

### 12.2 Contrast Ratios (Dark Mode)

| Element | Foreground | Background | Ratio |
|---|---|---|---|
| Primary text | `#F4F4F5` | `#09090B` | 18.2:1 ✅ |
| Secondary text | `#A1A1AA` | `#09090B` | 7.3:1 ✅ |
| Tertiary text | `#71717A` | `#09090B` | 4.6:1 ✅ |
| Brand accent | `#E63946` | `#09090B` | 5.1:1 ✅ |
| Success | `#06D6A0` | `#09090B` | 8.7:1 ✅ |
| Warning | `#FFC857` | `#09090B` | 12.4:1 ✅ |
| Error | `#EF476F` | `#09090B` | 5.4:1 ✅ |

---

## 13. Performance Guidelines

| Guideline | Target |
|---|---|
| **Initial cold start** | < 2 seconds to interactive |
| **Tab switch** | < 16ms (single frame) |
| **Pull-to-refresh** | < 500ms for data reload |
| **Chart rendering** | < 200ms for full chart paint |
| **DB operations** | All async, no UI blocking |
| **Memory usage** | < 80MB RSS |
| **APK size** | < 25MB |
| **Battery impact** | < 2% per hour (background monitoring) |

### 13.1 Optimization Techniques

- Use `const` constructors everywhere possible
- `IndexedStack` for tab preservation (no rebuild)
- `RepaintBoundary` around expensive widgets (charts, gauges)
- Image caching for app icons (base64 decode once, cache)
- Debounce search input (300ms)
- Lazy-load exercise history and analytics data
- Use `AutomaticKeepAliveClientMixin` for tab state preservation

---

## 14. File Structure

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # MaterialApp, routing
│   └── theme/
│       ├── app_colors.dart            # Color tokens (Section 3)
│       ├── app_theme.dart             # ThemeData (light + dark)
│       ├── app_typography.dart        # Text styles (Section 4)
│       ├── app_spacing.dart           # Spacing + radii tokens (Section 5)
│       └── app_motion.dart            # Animation curves + durations (Section 8)
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   ├── database/
│   │   ├── app_database.dart          # SQLite database class
│   │   └── database_tables.dart       # Table schemas
│   ├── platform/
│   │   └── native_app_service.dart    # MethodChannel bridge
│   ├── services/
│   │   ├── break_service.dart         # Break session logic
│   │   ├── pin_service.dart           # PIN generation/validation
│   │   ├── report_service.dart        # PDF report generation
│   │   └── usage_monitor_service.dart # Usage tracking orchestrator
│   └── utils/
│       ├── date_utils.dart            # Date formatting helpers
│       └── formatters.dart            # Time/number formatters
│
├── features/
│   ├── analytics/
│   │   └── presentation/
│   │       └── analytics_screen.dart
│   ├── app_management/
│   │   └── presentation/
│   │       ├── app_list_screen.dart
│   │       └── app_selector_sheet.dart
│   ├── app_rules/
│   │   └── presentation/
│   │       └── rule_config_screen.dart
│   ├── breaks/
│   │   └── presentation/
│   │       └── break_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│   ├── exercises/
│   │   └── presentation/
│   │       ├── exercise_library_screen.dart
│   │       └── exercise_session_screen.dart
│   ├── monitoring/
│   │   └── providers/
│   │       └── monitoring_providers.dart
│   ├── onboarding/
│   │   └── presentation/
│   │       └── onboarding_screen.dart
│   ├── overrides/
│   │   └── presentation/
│   │       └── override_dialog.dart
│   ├── pin_management/
│   │   └── presentation/
│   │       ├── pin_entry_screen.dart
│   │       └── show_pin_screen.dart
│   ├── profile/
│   │   └── presentation/
│   │       └── profile_screen.dart
│   ├── reports/
│   │   └── presentation/
│   │       └── reports_screen.dart
│   └── settings/
│       ├── presentation/
│       │   └── settings_screen.dart
│       └── providers/
│           └── theme_provider.dart
│
└── shared/
    ├── models/
    │   ├── analytics_summary.dart
    │   ├── app_rule.dart
    │   ├── break_session.dart
    │   ├── daily_usage.dart
    │   ├── exercise.dart
    │   ├── exercise_log.dart
    │   ├── monitored_app.dart
    │   ├── override_log.dart
    │   └── pin_state.dart
    └── widgets/
        ├── app_icon_view.dart         # Base64 icon decoder
        ├── circular_usage_gauge.dart  # NEW: Hero gauge widget
        ├── countdown_timer.dart       # NEW: Break timer widget
        ├── ezze_button.dart           # Primary button component
        ├── ezze_card.dart             # Glassmorphic card
        ├── pin_input_field.dart       # NEW: 8-cell PIN input
        └── status_badge.dart          # Pill badge component
```

---

## 15. Implementation Checklist

### Phase 1: Design System Foundation
- [ ] Download and bundle Inter + JetBrains Mono fonts
- [ ] Update `app_colors.dart` with new color system (Section 3)
- [ ] Create `app_typography.dart` with text style scale (Section 4)
- [ ] Create `app_spacing.dart` with spacing tokens (Section 5)
- [ ] Create `app_motion.dart` with animation constants (Section 8)
- [ ] Update `app_theme.dart` with new ThemeData for both modes
- [ ] Update `EzzeCard` with glassmorphic styling
- [ ] Update `EzzeButton` with gradient + press animation
- [ ] Update `StatusBadge` with new color variants
- [ ] Create `CircularUsageGauge` widget
- [ ] Create `CountdownTimer` widget
- [ ] Create `PinInputField` widget

### Phase 2: Navigation & Shell
- [ ] Replace `BottomNavigationBar` with custom animated nav bar
- [ ] Add sliding pill indicator animation
- [ ] Add page transition animations (shared axis)
- [ ] Update FAB styling and press animation

### Phase 3: Screen Redesigns
- [ ] Splash screen with brand animation
- [ ] Onboarding flow with staggered animations
- [ ] Dashboard with circular gauge hero
- [ ] My Apps with filter chips and search
- [ ] App Selector bottom sheet redesign
- [ ] Rule Configuration with slider redesign
- [ ] Insights with enhanced chart styling
- [ ] Break Enforcement with immersive timer
- [ ] Exercise Session with progress dots
- [ ] Exercise Library with tabs and history
- [ ] Override Dialog with duration chips
- [ ] PIN Entry with custom cells and animations
- [ ] Show PIN with copy and countdown
- [ ] Profile with avatar and stat cards
- [ ] Settings with segmented theme control
- [ ] Reports with content checklist

### Phase 4: Polish & QA
- [ ] Dark mode comprehensive review
- [ ] Light mode comprehensive review
- [ ] Accessibility audit (contrast, semantics, touch targets)
- [ ] Performance profiling (jank, memory)
- [ ] Animation smoothness verification
- [ ] Edge cases (empty states, error states, loading states)
- [ ] Physical device testing on multiple screen sizes
- [ ] Flutter analyze: 0 issues
- [ ] Flutter test: all passing

---

> **Note for AI Continuity:** This document is the single source of truth for the Ezze Break UI/UX redesign. Any AI model continuing this work should read this entire document before making code changes. The existing codebase at `f:\EzzeBreak\lib\` contains the v1.0 implementation. This design document specifies the v2.0 redesign target. All existing functionality must be preserved—only the visual layer and interaction patterns should change.
