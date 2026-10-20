# Ezze Break

> **Use mindfully. Move regularly. Feel better.**

Ezze Break is a complete, 100% offline-first Android digital wellbeing application built with Flutter, Dart, and native Kotlin. It empowers users to establish intentional screen-time boundaries, take regular physical movement breaks, consciously override restrictions with a cryptographic daily PIN, and analyze their digital habits through offline local charts and exportable PDF reports.

---

## 1. What Ezze Break Is

Ezze Break is a privacy-first screen-time management and movement reminder tool designed to prevent passive, uninterrupted device usage. Unlike typical digital wellbeing applications that rely on cloud accounts, server telemetry, or subscription paywalls, Ezze Break operates **entirely on your device**. All usage accounting, application rules, exercise records, and PIN validations remain local and private.

---

## 2. Key Features

1. **Granular Usage Control:** Configure distinct daily allowances (e.g., 1 hour) and continuous uninterrupted session limits (e.g., 20 minutes) for any installed application.
2. **Break State Machine:** When a continuous session limit expires, the app is blocked and a structured break routine begins.
3. **Physical Movement Library:** Integrate real physical activities—such as squats, push-ups, planks, and jumping jacks—into your break requirements.
4. **8-Digit Cryptographic Daily PIN:** A secure self-control mechanism generated locally every 24 hours. The PIN requires intentional, deliberate entry to unlock apps after a break or grant a temporary daily extension.
5. **Intentional Overrides:** Explicit extension requests (e.g., 5, 10, or 15 minutes) when daily budgets are exhausted, preventing endless mindless scrolling while accommodating genuine needs.
6. **Local Visual Analytics:** Real-time donut charts displaying app usage share, plus 7-day bar trend charts comparing active screen time against configured budgets.
7. **Vector PDF Reports:** One-tap export of clean, printable wellbeing reports directly saved to the device's public Downloads folder.
8. **100% Offline Privacy:** Zero internet permissions, no external dependencies, no accounts, and no data tracking.

---

## 3. Screens and Navigation

Ezze Break utilizes a clean Material 3 bottom navigation bar with four primary destinations:

- **1. Home (Dashboard):**
  - Daily overview cards: Total screen time, monitored app count, breaks triggered/completed, and overrides used today.
  - Active monitored application cards featuring real-time linear progress bars.
  - Quick action chips: "Add App", "Show PIN", "Exercise Library", "Export Report", and "Monitoring Status".
  - Floating Action Button (FAB) for instant app selection.
- **2. My Apps:**
  - Complete list of active monitored apps and disabled apps.
  - Per-app rule indicators: daily allowance, continuous limit, break duration, and assigned exercises.
  - Native Installed App Discovery modal with instantaneous search and Base64 icon rendering.
  - Per-app Rule Configuration Screen for fine-tuning budgets and exercises.
- **3. Insights:**
  - Date filtering: "Today", "Yesterday", and "Last 7 Days".
  - Interactive Donut chart showing usage distribution across monitored apps.
  - Weekly 7-day bar chart showing daily usage vs daily allowances.
  - Summary metrics: Average session length, completion rate, and exercise totals.
  - Direct shortcut to PDF Report Generator.
- **4. Profile & Settings:**
  - Optional local display name customization.
  - Theme mode selector: Light, Dark, or System Default.
  - System permission health indicators (Usage Access, Overlay, Accessibility, Notification).
  - Data management: Clear usage history or perform a full factory reset with confirmation.

---

## 4. Technologies Used

- **Framework:** Flutter (Channel stable, 3.41.7) & Dart 3.11.5
- **Native Android:** Kotlin (targetSdk 34, minSdk 26, Gradle 8.14)
- **Design System:** Material 3 with custom Ezze Break tokens (Primary Red `#D92D3E`, Deep Black `#080808`, Off-White `#FAFAFB`)
- **State Management:** Riverpod 2.0 (`flutter_riverpod`)
- **Local Persistence:** SQLite via `sqflite` (10 relational tables) & `shared_preferences`
- **Charts:** `fl_chart` for responsive vector donut and bar charts
- **PDF Generation:** `pdf` and `printing`
- **Testing:** `flutter_test` and `sqflite_common_ffi`

---

## 5. Project Architecture

The codebase follows Clean Architecture with clear layer boundaries:
- `lib/core/`: SQLite database repository, date formatters, and native MethodChannel wrappers.
- `lib/features/`: Cohesive feature modules containing domain services, Riverpod providers, and presentation screens.
- `lib/shared/`: Immutable models, common Ezze design system widgets (`EzzeCard`, `EzzeButton`, `EzzeProgressBar`).
- `android/`: Native Kotlin implementation for Accessibility events, full-screen restriction overlay, and MediaStore Downloads integration.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architectural diagrams.

---

## 6. Prerequisites

- **Flutter SDK:** Version 3.24.0 or higher
- **Android SDK:** API Level 34+ installed via Android Studio
- **Java Development Kit (JDK):** Version 17 or higher
- **Android Device or Emulator:** Running Android 8.0 (API 26) or higher

---

## 7. Flutter Setup

Verify your environment by running:
```bash
flutter doctor
```
Install project dependencies:
```bash
flutter pub get
```

---

## 8. How to Run the Project in VS Code

1. Open VS Code in the project root:
   ```bash
   code f:\EzzeBreak
   ```
2. Select your connected Android device or running emulator from the device picker at the bottom-right status bar.
3. Press `F5` or select **Run > Start Debugging**.

---

## 9. Launching on an Emulator or Physical Phone

Run directly via the Flutter CLI:
```bash
# Check connected devices
flutter devices

# Launch on selected device
flutter run
```

---

## 10. Configuring Required Android Permissions

Upon initial launch, Ezze Break presents an intuitive 5-step onboarding guide. You can also review or update permissions at any time from **Profile > Permission Status**:

1. **Usage Access (`PACKAGE_USAGE_STATS`):**
   - *Why needed:* Measures exact foreground usage timestamps of monitored applications.
   - *Route:* Settings > Apps > Special app access > Usage access > Ezze Break > Allow.
2. **Display Over Other Apps (`SYSTEM_ALERT_WINDOW`):**
   - *Why needed:* Presents the full-screen restriction barrier when a session or daily limit expires.
   - *Route:* Settings > Apps > Special app access > Display over other apps > Ezze Break > Allow.
3. **Accessibility Service (`EzzeAccessibilityService`):**
   - *Why needed:* Instantly detects when a restricted app is launched in the foreground to prevent bypassing limits.
   - *Route:* Settings > Accessibility > Downloaded apps > Ezze Break > Enable.
4. **Notifications (`POST_NOTIFICATIONS`):**
   - *Why needed:* Sends break reminders and limit warnings on Android 13+.

See [docs/ANDROID_PERMISSIONS.md](docs/ANDROID_PERMISSIONS.md) for detailed platform explanations.

---

## 11. How Usage Monitoring Works

- **Foreground Attribution:** `UsageMonitorService` continuously reconciles active foreground applications via `UsageStatsManager` and accessibility transition events.
- **Session vs. Daily Tracking:**
  - *Continuous Session Duration:* Measures the active, uninterrupted time during the current session. Taking a verified break resets this timer to 0.
  - *Daily Accumulated Usage:* Tracks total active seconds within the current local calendar day (`yyyy-MM-dd`). Taking a break **does not** reset daily usage.
- **Periodic Sync:** Usage is flushed to SQLite every 10 seconds and upon application lifecycle pause/resume.

---

## 12. How the Restriction Mechanism Works

1. When an application hits its continuous session limit or daily budget, `UsageMonitorService` marks the app restricted and synchronizes with native `EzzeRestrictionManager`.
2. When the user attempts to interact with the restricted app, `EzzeAccessibilityService` intercepts the window change and immediately launches `RestrictionActivity`.
3. `RestrictionActivity` presents a non-dismissible modal overlay that blocks back-navigation, presenting two options:
   - **Start Break:** Opens Ezze Break directly into the break and exercise flow.
   - **Use Anyway:** Opens Ezze Break to the PIN-authenticated extension dialog.

---

## 13. Known Android Limitations

- **System Application Exemptions:** To prevent lockouts, Ezze Break never restricts critical system applications, phone dialers, system settings, or the device launcher.
- **OEM Background Restrictions:** Aggressive battery managers (such as MIUI, ColorOS, or EMUI) may kill background services if battery optimization is not turned off for Ezze Break.
- **Non-Admin Design:** Ezze Break is a self-control tool, not an enterprise MDM device lock. A user with physical device ownership can uninstall the app or force-stop it via system settings.

---

## 14. Local Database Design

The application stores all data in a local SQLite database (`ezze_break.db`):
- `user_profile`: Local display name and preferences.
- `monitored_apps`: Package IDs, application names, and Base64 icon strings.
- `app_rules`: Per-app daily budgets, session limits, and break configurations.
- `usage_sessions`: Individual foreground usage sessions.
- `daily_usage`: Daily aggregates per app per local calendar day.
- `break_sessions`: Break lifecycle states and timestamps.
- `exercise_definitions`: Library of physical exercise routines.
- `exercise_logs`: Completed repetition and duration records.
- `pin_state`: 24-hour cryptographic PIN and expiration timestamp.
- `override_logs`: Authorized daily limit extension history.

See [docs/DATABASE.md](docs/DATABASE.md) for complete schema DDL.

---

## 15. PIN Rotation and Validation Behavior

- **Secure Generation:** Generated using Dart's cryptographically secure random generator: `Random.secure()`.
- **8 Decimal Digits:** Formatted as an 8-character string with full leading-zero preservation (e.g., `04829103`).
- **24-Hour Rolling Window:** The PIN remains valid for exactly 24 hours from generation. When the expiration timestamp passes, a new PIN is automatically generated on next app resume.
- **Rate Limiting:** Entering an invalid PIN 5 consecutive times triggers an automatic 30-second lockout to discourage rapid guessing.

---

## 16. How Daily Usage Budgets Work

- Every monitored application can have an individual daily budget (e.g. 15m, 30m, 1h, 2h).
- Daily usage resets at midnight according to the device's local calendar day.
- When an app reaches its daily limit, Ezze Break displays:
  > *"App usage time limit over. Please use it tomorrow."*
- Users can choose **Return to Home** or **Use Anyway**. The override flow requires entering the 8-digit daily PIN and selecting a temporary extension (5, 10, or 15 minutes).

---

## 17. Exercise Tracking Behavior

- Ezze Break includes built-in exercises:
  - Repetition-based: Push-ups, Sit-ups, Squats, Pull-ups, Jumping Jacks, Lunges.
  - Duration-based: Plank, Stretching, Walking.
- Users can define custom exercises with custom rep/duration targets.
- Exercise completion requires active user confirmation on the completion checklist before entering the PIN to resume normal app usage.

---

## 18. How Analytics Are Calculated

All analytics are computed dynamically from SQLite tables:
- **Usage Share:** Calculated as `(appAccumulatedSeconds / totalAccumulatedSeconds) * 100` and visualized via an interactive Donut chart.
- **7-Day Trend:** Groups `daily_usage` records by `date_key` across the last 7 calendar days and renders a comparative bar chart against configured daily allowances.
- **Accuracy Guarantee:** Distinguishes between measured foreground time and temporary override time.

---

## 19. How to Export PDF Reports

1. In Ezze Break, navigate to **Insights > Export PDF Report** or tap the quick action on the Dashboard.
2. Select the date range: **Today's Report** or **Last 7 Days Report**.
3. Tap **Generate & Save PDF**.
4. The file is saved directly into your device's public **Downloads** directory using Android's native `MediaStore.Downloads` API (e.g., `EzzeBreak_Report_2026-10-20.pdf`).
5. A confirmation dialog appears with an option to open the file immediately in your preferred PDF viewer via Android's `FileProvider`.

---

## 20. How to Run Tests

Run the complete 34-test automated suite:
```bash
flutter test
```
See [docs/TESTING.md](docs/TESTING.md) for details on unit and widget tests.

---

## 21. How to Generate a Debug APK

```bash
flutter build apk --debug
```
The resulting APK is located at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 22. How to Generate a Signed Release APK or App Bundle

```bash
# Release APK
flutter build apk --release

# Release App Bundle (for Google Play)
flutter build appbundle --release
```
See [docs/RELEASE.md](docs/RELEASE.md) for keystore configuration instructions.

---

## 23. Privacy and Offline Architecture

- **No Remote Telemetry:** Ezze Break contains zero analytics SDKs (no Firebase, no Mixpanel, no Sentry).
- **No Network Permissions:** The Android manifest omits `android.permission.INTERNET`.
- **Zero Cloud Accounts:** No email, phone number, or login is required.
- **Local Data Erasure:** Full factory reset and data clearing can be executed in one tap from Settings.

---

## 24. Troubleshooting

- **Monitored App Not Detected:** Ensure **Usage Access** and **Accessibility Service** are enabled in Android Settings.
- **Overlay Not Appearing:** Check that **Display over other apps** permission is granted.
- **Restrictions Reset After Reboot:** Ezze Break automatically reconstructs active limits and restriction caches on device startup.

---

## 25. Future Improvement Opportunities

- Home screen glanceable widget showing daily remaining time and current break status.
- Wear OS companion application for vibration break reminders and rep counting.
- NFC tag scanning support as an alternative physical movement verification step.

---

## License

Personal and portfolio use. All rights reserved.
