import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ezze_break/core/database/app_database.dart';

Database? _previousTestDb;

Future<AppDatabase> setupTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  if (_previousTestDb != null && _previousTestDb!.isOpen) {
    try {
      await _previousTestDb!.close();
    } catch (_) {}
  }

  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, version) async {
      // Create tables using AppDatabase internal method via reflection or direct schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY,
          display_name TEXT,
          created_at INTEGER,
          updated_at INTEGER
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitored_apps (
          package_name TEXT PRIMARY KEY,
          app_name TEXT NOT NULL,
          icon_base64 TEXT,
          is_system_app INTEGER NOT NULL DEFAULT 0,
          is_monitored INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_rules (
          package_name TEXT PRIMARY KEY,
          daily_budget_minutes INTEGER NOT NULL,
          session_limit_minutes INTEGER NOT NULL,
          break_duration_minutes INTEGER NOT NULL,
          exercise_ids_json TEXT NOT NULL,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usage_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          package_name TEXT NOT NULL,
          session_start INTEGER NOT NULL,
          session_end INTEGER NOT NULL,
          duration_seconds INTEGER NOT NULL,
          source TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          package_name TEXT NOT NULL,
          date_key TEXT NOT NULL,
          accumulated_seconds INTEGER NOT NULL DEFAULT 0,
          allowance_minutes INTEGER NOT NULL DEFAULT 60,
          additional_seconds INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL,
          UNIQUE(package_name, date_key)
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS break_sessions (
          id TEXT PRIMARY KEY,
          package_name TEXT NOT NULL,
          trigger_time INTEGER NOT NULL,
          required_break_seconds INTEGER NOT NULL,
          current_state TEXT NOT NULL,
          completed_time INTEGER,
          pin_validated INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercise_definitions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          default_target INTEGER NOT NULL,
          description TEXT,
          is_custom INTEGER NOT NULL DEFAULT 0,
          is_enabled INTEGER NOT NULL DEFAULT 1
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercise_logs (
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
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pin_state (
          id INTEGER PRIMARY KEY,
          current_pin TEXT NOT NULL,
          window_start INTEGER NOT NULL,
          window_expires INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS override_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          package_name TEXT NOT NULL,
          original_budget_minutes INTEGER NOT NULL,
          usage_at_auth_seconds INTEGER NOT NULL,
          extension_minutes INTEGER NOT NULL,
          authorized_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        );
      ''');
    },
  );

  AppDatabase.setMockDatabase(db);
  _previousTestDb = db;
  return AppDatabase.instance;
}
