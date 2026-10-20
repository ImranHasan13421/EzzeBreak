# Ezze Break Architecture

## 1. System Overview

Ezze Break is built as an offline-first, high-privacy Android digital wellbeing application. The application pairs a high-performance Flutter/Dart front end with a dedicated Android Kotlin platform integration layer.

```
+---------------------------------------------------------------------------------+
|                                 Ezze Break UI                                   |
|  [Onboarding]   [Dashboard]   [My Apps]   [Breaks/Exercises]  [Insights/PDF]    |
+---------------------------------------------------------------------------------+
                                       |
                                       v
+---------------------------------------------------------------------------------+
|                       State Management (Riverpod 2.0)                          |
|  * permissionsProvider          * monitoredAppsListProvider                     |
|  * pinStateNotifierProvider     * todayUsageProvider                            |
|  * themeProvider                * activeBreakNotifierProvider                   |
+---------------------------------------------------------------------------------+
                                       |
                                       v
+---------------------------------------------------------------------------------+
|                         Core Domain Services (Dart)                             |
|  * UsageMonitorService: Time accounting (Session vs Daily)                      |
|  * BreakService: Break state machine & exercise verification                   |
|  * PinService: Cryptographic 8-digit PIN & 24h rolling window                  |
|  * ReportService: Aggregation & Vector PDF Generation (Downloads)              |
+---------------------------------------------------------------------------------+
                    |                                             |
                    v                                             v
+---------------------------------------+     +-----------------------------------+
|         Local SQLite Database         |     |      Platform Channel Bridge      |
|  10 relational tables (sqflite)       |     |  MethodChannel: com.ezze.break    |
|  Single device source of truth        |     +-----------------------------------+
+---------------------------------------+                       |
                                                                v
+---------------------------------------------------------------------------------+
|                        Native Android Layer (Kotlin)                            |
|  * MainActivity: PackageManager queries, icon extraction, MediaStore saver     |
|  * EzzeAccessibilityService: Foreground window transition detection            |
|  * EzzeRestrictionManager: SharedPreferences sync & thread-safe restriction    |
|  * RestrictionActivity: Full-screen modal barrier overlay                      |
+---------------------------------------------------------------------------------+
```

---

## 2. Directory Structure

```text
lib/
├── app/
│   ├── app.dart                    # MaterialApp & Root BottomNavigationBar
│   └── theme/
│       ├── app_colors.dart         # Red, Black, White Brand Color Tokens
│       └── app_theme.dart          # Light & Dark Material 3 Themes
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Platform channel, limits, defaults
│   ├── database/
│   │   ├── app_database.dart       # SQLite Repository & CRUD Operations
│   │   └── database_tables.dart    # DDL Table Schemas & Indices
│   ├── platform/
│   │   └── native_app_service.dart # Dart wrapper for Android MethodChannel
│   ├── services/
│   │   ├── break_service.dart      # Break lifecycle state machine
│   │   ├── pin_service.dart        # 8-digit cryptographic PIN generator
│   │   ├── report_service.dart     # PDF generation & downloads saving
│   │   └── usage_monitor_service.dart # Continuous & daily usage accounting
│   └── utils/
│       ├── date_utils.dart         # Date formatting, ranges, day boundaries
│       └── formatters.dart         # Duration and count formatters
├── features/
│   ├── analytics/
│   │   └── presentation/analytics_screen.dart # Donut chart & 7-day usage trends
│   ├── app_management/
│   │   └── presentation/
│   │       ├── app_list_screen.dart     # Monitored apps listing & rules overview
│   │       └── app_selector_sheet.dart  # Native installed app discovery
│   ├── app_rules/
│   │   └── presentation/rule_config_screen.dart # Per-app budget & break settings
│   ├── breaks/
│   │   └── presentation/break_screen.dart       # Break countdown & exercise router
│   ├── dashboard/
│   │   └── presentation/dashboard_screen.dart   # Central monitoring overview
│   ├── exercises/
│   │   └── presentation/
│   │       ├── exercise_library_screen.dart     # Built-in & custom exercise manager
│   │       └── exercise_session_screen.dart     # Interactive rep counter & timer
│   ├── monitoring/
│   │   └── providers/monitoring_providers.dart  # Riverpod state notifiers
│   ├── onboarding/
│   │   └── presentation/onboarding_screen.dart  # 5-step interactive first run
│   ├── overrides/
│   │   └── presentation/override_dialog.dart    # Daily limit temporary extension
│   ├── pin_management/
│   │   └── presentation/
│   │       ├── pin_entry_screen.dart            # 8-box PIN keypad entry
│   │       └── show_pin_screen.dart             # Current PIN & validity countdown
│   ├── profile/
│   │   └── presentation/profile_screen.dart     # Profile info & data management
│   ├── reports/
│   │   └── presentation/reports_screen.dart     # PDF report preview & export
│   └── settings/
│       ├── presentation/settings_screen.dart    # Theme, reset, permission health
│       └── providers/theme_provider.dart        # Theme mode preference state
└── shared/
    ├── models/
    │   ├── app_rule.dart           # Per-app rule entity
    │   ├── break_session.dart      # Break session lifecycle model
    │   ├── daily_usage.dart        # Accumulated daily usage record
    │   ├── exercise.dart           # Exercise definition model
    │   ├── exercise_log.dart       # Completed exercise entry
    │   ├── monitored_app.dart      # Monitored app entity with icon Base64
    │   ├── override_log.dart       # Daily budget override record
    │   ├── pin_state.dart          # 8-digit PIN state & validity window
    │   └── usage_session.dart      # Individual usage session record
    └── widgets/
        ├── ezze_button.dart        # Styled brand action button
        ├── ezze_card.dart          # Subtle elevation card
        ├── ezze_progress_bar.dart  # Usage ratio indicator
        └── ezze_text_field.dart    # Form text input
```

---

## 3. Communication Architecture (MethodChannel)

The Flutter app communicates with native Android code through a unified platform channel:
- **Channel Name:** `com.ezze.break/channel`
- **Native Implementation:** `MainActivity.kt`, `EzzeRestrictionManager.kt`

### Method Channel Calls

| Method | Source | Destination | Purpose |
| :--- | :--- | :--- | :--- |
| `getInstalledApps` | Dart | Kotlin | Enumerates launcher apps with name, package, and Base64 PNG icon |
| `checkUsagePermission` | Dart | Kotlin | Checks if `PACKAGE_USAGE_STATS` is granted |
| `openUsageSettings` | Dart | Kotlin | Launches Android Usage Access settings intent |
| `checkOverlayPermission` | Dart | Kotlin | Checks if `SYSTEM_ALERT_WINDOW` is granted |
| `openOverlaySettings` | Dart | Kotlin | Launches Manage Overlay settings intent |
| `checkAccessibilityPermission` | Dart | Kotlin | Checks if `EzzeAccessibilityService` is active |
| `openAccessibilitySettings` | Dart | Kotlin | Launches Accessibility Settings intent |
| `updateRestrictions` | Dart | Kotlin | Syncs restricted packages to native SharedPreferences |
| `triggerRestriction` | Dart | Kotlin | Fires `RestrictionActivity` over a restricted app |
| `savePdfToDownloads` | Dart | Kotlin | Writes PDF bytes into Android MediaStore Downloads folder |
| `openFile` | Dart | Kotlin | Opens exported file via `FileProvider` and `ACTION_VIEW` |
| `getPendingAction` | Dart | Kotlin | Retrieves pending intent action from native notification/overlay |

---

## 4. State Machine Architecture (Break Sessions)

```
       +------------------------------------+
       |                IDLE                |
       +------------------------------------+
                         |
           (Continuous session limit hit)
                         v
       +------------------------------------+
       |           BREAK_REQUIRED           |
       +------------------------------------+
                         |
              (User opens Ezze Break)
                         v
       +------------------------------------+
       |          BREAK_IN_PROGRESS         |
       +------------------------------------+
                         |
           (Break timer reaches zero)
                         v
       +------------------------------------+
       |        EXERCISE_IN_PROGRESS        |
       +------------------------------------+
                         |
        (All required exercises confirmed)
                         v
       +------------------------------------+
       |            AWAITING_PIN            |
       +------------------------------------+
                         |
            (Valid 8-digit PIN entered)
                         v
       +------------------------------------+
       |         ELIGIBLE_TO_RESUME         |
       +------------------------------------+
                         |
           (Session timer resets to 0;
            Daily accumulated time preserved)
                         v
       +------------------------------------+
       |                IDLE                |
       +------------------------------------+
```
