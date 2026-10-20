# Ezze Break - Automated & Manual Testing Guide

## 1. Test Strategy Overview

Ezze Break implements comprehensive automated tests covering critical business logic, time calculations, cryptographic PIN generation, break state machines, and widget interactions.

All tests are designed to run fast and deterministically:
- **Injectable Clocks:** Deterministic time mocking avoids `sleep()` or real-time delays.
- **SQLite FFI In-Memory Database:** Database tests run with SQLite in-memory without persistent disk pollution.
- **Mock SharedPreferences & Platform Channels:** Isolated unit tests prevent native channel exceptions.

---

## 2. Test Suite Breakdown

### Unit Tests (`test/unit/`)

#### 1. PIN Management (`test/unit/pin_service_test.dart`)
- **8-Digit PIN Generation:** Verified using `Random.secure()` to guarantee exactly 8 decimal characters.
- **Leading Zero Preservation:** Verified string representation retains leading zeros (`00123456`).
- **24-Hour Rolling Validity Window:** Verified PIN stays unchanged within 24 hours and rotates upon expiration.
- **Rate-Limiting Lockout:** Verified 5 incorrect attempts trigger a 30-second lockout.
- **Manual Rotation:** Verified `rotatePinNow()` generates a fresh PIN and resets the 24-hour window.

#### 2. Date Utilities & Formatters (`test/unit/date_utils_test.dart`)
- **Date Keys:** Verified `yyyy-MM-dd` local day string generation and parsing.
- **Start/End of Day:** Verified midnight boundary timestamps for analytics filters.
- **7-Day Windows:** Verified sliding window bounds for weekly trends.
- **Formatters:** Verified seconds to `Xh Ym` and count formatting.

#### 3. Database & PDF Reporting (`test/unit/database_test.dart`)
- **Monitored App CRUD:** Adding, updating, and querying apps with icons.
- **Per-App Rules:** Saving and reading budget, session, and break rules.
- **Usage Sessions & Daily Totals:** Recording incremental seconds and updating daily records.
- **Exercise Library & Logs:** Logging completed repetitions and duration.
- **PIN State Persistence:** Single-row replacement and retrieval.
- **Overrides:** Recording daily budget extensions.
- **ReportService & PDF Generation:** Computing 7-day analytics and rendering vector PDF bytes without errors.
- **Data Deletion:** Verifying history clearing and factory reset.

#### 4. Usage Accounting & Break State Machine (`test/unit/usage_monitor_test.dart`)
- **Session vs Daily Usage:** Incrementing continuous session alongside daily total.
- **Break Release:** Resetting continuous session to 0 while preserving daily accumulated seconds.
- **Limit Exhaustion:** Triggering native restriction updates when daily budget is hit.
- **Override Authorization:** Validating PIN and extending daily budget.

### Widget Tests (`test/widget_test.dart`)
- **Onboarding Flow:** Renders pages, title, and responds to "Get Started".
- **Dashboard Screen:** Header, greeting, total screen time, quick actions, and app cards.
- **PIN Entry Screen:** 8 visual boxes, keypad digit taps, and backspace.
- **Show PIN Screen:** PIN display, remaining validity countdown, and clipboard copy.
- **Override Dialog:** Daily limit exhaustion warning, extension options, and PIN submit.

---

## 3. Running Automated Tests

Run the complete test suite:
```bash
flutter test
```

Run specific test files:
```bash
flutter test test/unit/pin_service_test.dart
flutter test test/unit/usage_monitor_test.dart
flutter test test/unit/database_test.dart
flutter test test/unit/date_utils_test.dart
flutter test test/widget_test.dart
```

---

## 4. Manual Verification Matrix (Real Android Device)

For physical testing on an Android 10+ device:

| Step | Action | Expected Result |
| :---: | :--- | :--- |
| 1 | Launch app for the first time | Onboarding screen appears; user sets optional display name. |
| 2 | Grant permissions | Usage Access, Overlay (`SYSTEM_ALERT_WINDOW`), and Accessibility settings open and toggle successfully. |
| 3 | Add Monitored App | Tap "Add App" floating action button; real installed apps list with icons is displayed; select app (e.g. YouTube). |
| 4 | Configure Rule | Set session limit to 1 minute, daily budget to 15 minutes, break duration to 1 minute. |
| 5 | Trigger Session Break | Open YouTube and use for 1 minute; `RestrictionActivity` immediately covers the screen. |
| 6 | Complete Break | Tap "Start Break", review rest countdown, complete required squats/push-ups, tap Complete. |
| 7 | Enter PIN | View 8-digit PIN from Show PIN screen, enter in PIN keypad; app resumes with session reset to 0 min while preserving daily usage. |
| 8 | Trigger Daily Exhaustion | Use app until 15 minutes is reached; "App usage time limit over" appears. |
| 9 | Request Override | Tap "Use Anyway", enter 8-digit PIN, select 5 minutes; 5-minute temporary extension is granted. |
| 10 | Export Report | Navigate to Insights -> Export Report -> "Today's Report" -> Save PDF; file is saved to Downloads folder and opens in system PDF viewer. |
| 11 | Switch Theme | In Settings, switch between Light, Dark, and System default; all cards, fonts, and charts update immediately. |
| 12 | Factory Reset | In Settings, tap "Clear All App Data"; all monitored apps, usage history, and rules are wiped cleanly. |
