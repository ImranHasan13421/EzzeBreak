# Ezze Break - Database Architecture & Schema Reference

## 1. Persistence Overview

Ezze Break uses a local SQLite database (`ezze_break.db`, schema version 1) managed via `sqflite`. The database serves as the single source of truth for:
- Monitored application metadata and icons
- Per-application limits and rules
- Time accounting sessions and daily aggregations
- Break lifecycle sessions
- Built-in and custom physical exercises
- Exercise completion logs
- 24-hour cryptographic PIN state
- Daily limit override audit logs

---

## 2. Relational Table Schemas

### `user_profile`
Stores optional local profile settings without cloud synchronization or account creation.
- `id` (INTEGER PRIMARY KEY)
- `display_name` (TEXT)
- `created_at` (INTEGER, Epoch ms)
- `updated_at` (INTEGER, Epoch ms)

### `monitored_apps`
Stores apps selected by the user for wellbeing management.
- `package_name` (TEXT PRIMARY KEY) - Android package identifier (e.g. `com.instagram.android`)
- `app_name` (TEXT NOT NULL) - Display name
- `icon_base64` (TEXT) - PNG icon serialized in Base64 for instant, offline rendering
- `is_system_app` (INTEGER NOT NULL DEFAULT 0) - Flag for system vs third-party app
- `is_monitored` (INTEGER NOT NULL DEFAULT 1) - Active monitoring toggle
- `created_at` (INTEGER NOT NULL, Epoch ms)
- `updated_at` (INTEGER NOT NULL, Epoch ms)

### `app_rules`
Defines daily allowances and session rules per application.
- `package_name` (TEXT PRIMARY KEY) - Foreign key to `monitored_apps`
- `daily_budget_minutes` (INTEGER NOT NULL) - Maximum daily active time (e.g. 60 min)
- `session_limit_minutes` (INTEGER NOT NULL) - Continuous uninterrupted session limit (e.g. 20 min)
- `break_duration_minutes` (INTEGER NOT NULL) - Minimum required rest period (e.g. 5 min)
- `exercise_ids_json` (TEXT NOT NULL) - JSON array of selected exercise IDs
- `is_enabled` (INTEGER NOT NULL DEFAULT 1) - Rule toggle
- `created_at` (INTEGER NOT NULL, Epoch ms)
- `updated_at` (INTEGER NOT NULL, Epoch ms)

### `usage_sessions`
Granular record of foreground sessions.
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `package_name` (TEXT NOT NULL)
- `session_start` (INTEGER NOT NULL, Epoch ms)
- `session_end` (INTEGER NOT NULL, Epoch ms)
- `duration_seconds` (INTEGER NOT NULL)
- `source` (TEXT NOT NULL) - `'foreground_event'`, `'periodic_flush'`, or `'reconstruction'`
- `created_at` (INTEGER NOT NULL, Epoch ms)

### `daily_usage`
Aggregated usage per application per local calendar day (`yyyy-MM-dd`).
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `package_name` (TEXT NOT NULL)
- `date_key` (TEXT NOT NULL) - Local day string (e.g. `'2026-10-20'`)
- `accumulated_seconds` (INTEGER NOT NULL DEFAULT 0) - Total eligible foreground seconds
- `allowance_minutes` (INTEGER NOT NULL DEFAULT 60) - Configured budget snapshot
- `additional_seconds` (INTEGER NOT NULL DEFAULT 0) - Extra seconds granted via PIN override
- `updated_at` (INTEGER NOT NULL, Epoch ms)
- *Constraint:* `UNIQUE(package_name, date_key)`

### `break_sessions`
Audit trail and state machine persistence for triggered breaks.
- `id` (TEXT PRIMARY KEY) - UUID string
- `package_name` (TEXT NOT NULL)
- `trigger_time` (INTEGER NOT NULL, Epoch ms)
- `required_break_seconds` (INTEGER NOT NULL)
- `current_state` (TEXT NOT NULL) - `'idle'`, `'break_required'`, `'break_in_progress'`, `'exercise_in_progress'`, `'awaiting_pin'`, `'eligible_to_resume'`, `'cancelled_or_invalidated'`
- `completed_time` (INTEGER, Epoch ms)
- `pin_validated` (INTEGER NOT NULL DEFAULT 0)
- `created_at` (INTEGER NOT NULL, Epoch ms)

### `exercise_definitions`
Library of physical exercises (repetition-based and time-based).
- `id` (TEXT PRIMARY KEY) - Unique ID (e.g. `'push_ups'`, `'plank'`)
- `name` (TEXT NOT NULL) - Display name
- `type` (TEXT NOT NULL) - `'reps'` or `'duration'`
- `default_target` (INTEGER NOT NULL) - Default repetition count or seconds
- `description` (TEXT) - Instructional guidance
- `is_custom` (INTEGER NOT NULL DEFAULT 0) - Built-in vs user-created
- `is_enabled` (INTEGER NOT NULL DEFAULT 1)

### `exercise_logs`
Historical record of completed exercises.
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `exercise_id` (TEXT NOT NULL)
- `exercise_name` (TEXT NOT NULL)
- `repetitions` (INTEGER NOT NULL DEFAULT 0)
- `duration_seconds` (INTEGER NOT NULL DEFAULT 0)
- `break_session_id` (TEXT) - Associated break session, if performed during a break
- `package_name` (TEXT) - App that triggered the break
- `is_confirmed` (INTEGER NOT NULL DEFAULT 1)
- `completed_at` (INTEGER NOT NULL, Epoch ms)

### `pin_state`
Single-row table storing the active 24-hour cryptographic PIN.
- `id` (INTEGER PRIMARY KEY) - Constant 1
- `current_pin` (TEXT NOT NULL) - 8-digit decimal string with leading zero support (e.g. `'04829103'`)
- `window_start` (INTEGER NOT NULL, Epoch ms)
- `window_expires` (INTEGER NOT NULL, Epoch ms)
- `updated_at` (INTEGER NOT NULL, Epoch ms)

### `override_logs`
Audit record of intentional daily limit extensions.
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `package_name` (TEXT NOT NULL)
- `original_budget_minutes` (INTEGER NOT NULL)
- `usage_at_auth_seconds` (INTEGER NOT NULL)
- `extension_minutes` (INTEGER NOT NULL)
- `authorized_at` (INTEGER NOT NULL, Epoch ms)
- `expires_at` (INTEGER NOT NULL, Epoch ms)

---

## 3. Database Indexes

To maintain instant UI performance without lag:
- `idx_daily_usage_date`: `CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON daily_usage(date_key);`
- `idx_usage_sessions_pkg`: `CREATE INDEX IF NOT EXISTS idx_usage_sessions_pkg ON usage_sessions(package_name, session_start);`
- `idx_exercise_logs_time`: `CREATE INDEX IF NOT EXISTS idx_exercise_logs_time ON exercise_logs(completed_at);`
- `idx_break_sessions_state`: `CREATE INDEX IF NOT EXISTS idx_break_sessions_state ON break_sessions(current_state);`
