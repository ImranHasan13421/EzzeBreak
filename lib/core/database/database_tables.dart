class DatabaseTables {
  static const String tableUserProfile = 'user_profile';
  static const String tableMonitoredApps = 'monitored_apps';
  static const String tableAppRules = 'app_rules';
  static const String tableUsageSessions = 'usage_sessions';
  static const String tableDailyUsage = 'daily_usage';
  static const String tableBreakSessions = 'break_sessions';
  static const String tableExerciseDefinitions = 'exercise_definitions';
  static const String tableExerciseLogs = 'exercise_logs';
  static const String tablePinState = 'pin_state';
  static const String tableOverrideLogs = 'override_logs';

  static const String createTableUserProfile = '''
    CREATE TABLE IF NOT EXISTS $tableUserProfile (
      id INTEGER PRIMARY KEY,
      display_name TEXT,
      created_at INTEGER,
      updated_at INTEGER
    );
  ''';

  static const String createTableMonitoredApps = '''
    CREATE TABLE IF NOT EXISTS $tableMonitoredApps (
      package_name TEXT PRIMARY KEY,
      app_name TEXT NOT NULL,
      icon_base64 TEXT,
      is_system_app INTEGER NOT NULL DEFAULT 0,
      is_monitored INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''';

  static const String createTableAppRules = '''
    CREATE TABLE IF NOT EXISTS $tableAppRules (
      package_name TEXT PRIMARY KEY,
      daily_budget_minutes INTEGER NOT NULL,
      session_limit_minutes INTEGER NOT NULL,
      break_duration_minutes INTEGER NOT NULL,
      exercise_ids_json TEXT NOT NULL,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''';

  static const String createTableUsageSessions = '''
    CREATE TABLE IF NOT EXISTS $tableUsageSessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      package_name TEXT NOT NULL,
      session_start INTEGER NOT NULL,
      session_end INTEGER NOT NULL,
      duration_seconds INTEGER NOT NULL,
      source TEXT NOT NULL,
      created_at INTEGER NOT NULL
    );
  ''';

  static const String createTableDailyUsage = '''
    CREATE TABLE IF NOT EXISTS $tableDailyUsage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      package_name TEXT NOT NULL,
      date_key TEXT NOT NULL,
      accumulated_seconds INTEGER NOT NULL DEFAULT 0,
      allowance_minutes INTEGER NOT NULL DEFAULT 60,
      additional_seconds INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      UNIQUE(package_name, date_key)
    );
  ''';

  static const String createTableBreakSessions = '''
    CREATE TABLE IF NOT EXISTS $tableBreakSessions (
      id TEXT PRIMARY KEY,
      package_name TEXT NOT NULL,
      trigger_time INTEGER NOT NULL,
      required_break_seconds INTEGER NOT NULL,
      current_state TEXT NOT NULL,
      completed_time INTEGER,
      pin_validated INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    );
  ''';

  static const String createTableExerciseDefinitions = '''
    CREATE TABLE IF NOT EXISTS $tableExerciseDefinitions (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      default_target INTEGER NOT NULL,
      description TEXT,
      is_custom INTEGER NOT NULL DEFAULT 0,
      is_enabled INTEGER NOT NULL DEFAULT 1
    );
  ''';

  static const String createTableExerciseLogs = '''
    CREATE TABLE IF NOT EXISTS $tableExerciseLogs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_id TEXT NOT NULL,
      exercise_name TEXT NOT NULL,
      repetitions INTEGER NOT NULL DEFAULT 0,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      break_session_id TEXT,
      package_name TEXT,
      is_confirmed INTEGER NOT NULL DEFAULT 1,
      completed_at INTEGER NOT NULL
    );
  ''';

  static const String createTablePinState = '''
    CREATE TABLE IF NOT EXISTS $tablePinState (
      id INTEGER PRIMARY KEY,
      current_pin TEXT NOT NULL,
      window_start INTEGER NOT NULL,
      window_expires INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''';

  static const String createTableOverrideLogs = '''
    CREATE TABLE IF NOT EXISTS $tableOverrideLogs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      package_name TEXT NOT NULL,
      original_budget_minutes INTEGER NOT NULL,
      usage_at_auth_seconds INTEGER NOT NULL,
      extension_minutes INTEGER NOT NULL,
      authorized_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL
    );
  ''';

  static const List<String> indices = [
    'CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON $tableDailyUsage(date_key);',
    'CREATE INDEX IF NOT EXISTS idx_usage_sessions_pkg ON $tableUsageSessions(package_name, session_start);',
    'CREATE INDEX IF NOT EXISTS idx_exercise_logs_time ON $tableExerciseLogs(completed_at);',
    'CREATE INDEX IF NOT EXISTS idx_break_sessions_time ON $tableBreakSessions(trigger_time);',
    'CREATE INDEX IF NOT EXISTS idx_override_logs_pkg ON $tableOverrideLogs(package_name, expires_at);',
  ];
}
