# Ezze Break - Android Permissions & Platform Integration Guide

## 1. Permission Philosophy

Ezze Break is built on strict offline privacy principles:
- **Zero Internet Permissions:** `android.permission.INTERNET` is **never** requested or declared. The app has zero capability to contact external servers.
- **Minimal Privilege Principle:** Only system capabilities essential to digital wellbeing, foreground monitoring, overlay barriers, and PDF saving are requested.
- **Transparent User Guidance:** The application never attempts to trick the user or silently escalate permissions. Every permission is explicitly explained during onboarding and on the Settings screen.

---

## 2. Declared Android Permissions

| Permission | Protection Level | Purpose in Ezze Break | Settings Route |
| :--- | :--- | :--- | :--- |
| `android.permission.PACKAGE_USAGE_STATS` | Special Access (`appops`) | Measure foreground app usage timestamps and active sessions via `UsageStatsManager` | `android.settings.USAGE_ACCESS_SETTINGS` |
| `android.permission.SYSTEM_ALERT_WINDOW` | Special Access | Display full-screen modal restriction overlay (`RestrictionActivity`) when session/daily limits expire | `android.settings.action.MANAGE_OVERLAY_PERMISSION` |
| `android.permission.BIND_ACCESSIBILITY_SERVICE` | System Bound Service | Real-time foreground app transition detection (`EzzeAccessibilityService`) for immediate restriction triggers | `android.settings.ACCESSIBILITY_SETTINGS` |
| `android.permission.POST_NOTIFICATIONS` | Runtime (Android 13+ / API 33+) | Deliver timely break reminders and daily limit notifications | `android.settings.APP_NOTIFICATION_SETTINGS` |
| `android.permission.FOREGROUND_SERVICE` | Normal | Maintain persistent monitoring service health | N/A |
| `android.permission.QUERY_ALL_PACKAGES` | System / Sensitive | Enumerate installed applications for user selection in the My Apps dashboard | N/A |

---

## 3. Storage Architecture (Scoped Storage)

Ezze Break respects modern Android Scoped Storage:
- **No Legacy External Storage Permissions:** Neither `READ_EXTERNAL_STORAGE` nor `WRITE_EXTERNAL_STORAGE` is requested.
- **MediaStore Downloads API:** PDF reports are written directly to public downloads using Android's native `MediaStore.Downloads` collection (`MediaStore.Downloads.EXTERNAL_CONTENT_URI`) with MIME type `application/pdf`.
- **FileProvider Integration:** Android's `FileProvider` is configured with `file_paths.xml` granting temporary read URI permissions (`FLAG_GRANT_READ_URI_PERMISSION`) when viewing or sharing reports in external PDF readers.

---

## 4. Enforcement Architecture & Reality

### How Restrictions Work
1. When a continuous session limit or daily budget is exhausted, `UsageMonitorService` updates the native restriction map via `NativeAppService.updateRestrictions(...)`.
2. `EzzeRestrictionManager` synchronizes the restricted package set to Android `SharedPreferences`.
3. When the user launches or switches to the restricted app, `EzzeAccessibilityService` intercepts the `TYPE_WINDOW_STATE_CHANGED` event.
4. If the active package is currently restricted, `RestrictionActivity` is immediately launched as a top-level, single-task modal activity.
5. `RestrictionActivity` blocks touch and back-navigation (`onBackPressedDispatcher`), presenting the user with two intentional choices:
   - **Start Break:** Opens Ezze Break directly into the break routine.
   - **Use Anyway (PIN Override):** Opens Ezze Break to the intentional PIN-authenticated extension dialog.

### Limitations of Android Platform
- **No Tamper-Proof Root Claims:** A standard non-system Android application cannot prevent a device owner from force-stopping the app, disabling Accessibility in Android Settings, or rebooting into Safe Mode.
- **System Exemptions:** Ezze Break explicitly exempts itself, system settings, emergency dials, and Android launcher packages from being restricted, ensuring the user can never be locked out of their device.
