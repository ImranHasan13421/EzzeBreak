import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../shared/models/monitored_app.dart';
import '../../shared/models/app_rule.dart';
import '../../shared/models/break_session.dart';
import '../../shared/models/exercise.dart';
import '../../shared/models/exercise_log.dart';
import '../../shared/models/pin_state.dart';
import '../../shared/models/override_log.dart';
import '../../shared/models/daily_usage.dart';
import 'database_tables.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  // Allow setting in-memory database instance for testing
  static void setMockDatabase(Database db) {
    _instance = AppDatabase._().._db = db;
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDefaultExercises(db);
      },
    );
  }

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute(DatabaseTables.createTableUserProfile);
    await db.execute(DatabaseTables.createTableMonitoredApps);
    await db.execute(DatabaseTables.createTableAppRules);
    await db.execute(DatabaseTables.createTableUsageSessions);
    await db.execute(DatabaseTables.createTableDailyUsage);
    await db.execute(DatabaseTables.createTableBreakSessions);
    await db.execute(DatabaseTables.createTableExerciseDefinitions);
    await db.execute(DatabaseTables.createTableExerciseLogs);
    await db.execute(DatabaseTables.createTablePinState);
    await db.execute(DatabaseTables.createTableOverrideLogs);

    for (final indexSql in DatabaseTables.indices) {
      await db.execute(indexSql);
    }
  }

  static Future<void> _seedDefaultExercises(DatabaseExecutor db) async {
    final defaults = Exercise.defaultExercises();
    for (final ex in defaults) {
      await db.insert(
        DatabaseTables.tableExerciseDefinitions,
        ex.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // --- Monitored Apps ---

  Future<List<MonitoredApp>> getAllMonitoredApps({bool activeOnly = false}) async {
    final db = await database;
    final where = activeOnly ? 'is_monitored = 1' : null;
    final maps = await db.query(DatabaseTables.tableMonitoredApps, where: where, orderBy: 'app_name ASC');
    return maps.map(MonitoredApp.fromMap).toList();
  }

  Future<MonitoredApp?> getMonitoredApp(String packageName) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableMonitoredApps,
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MonitoredApp.fromMap(maps.first);
  }

  Future<void> upsertMonitoredApp(MonitoredApp app) async {
    final db = await database;
    await db.insert(
      DatabaseTables.tableMonitoredApps,
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setAppMonitoredStatus(String packageName, bool isMonitored) async {
    final db = await database;
    await db.update(
      DatabaseTables.tableMonitoredApps,
      {
        'is_monitored': isMonitored ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> removeMonitoredApp(String packageName) async {
    // Set is_monitored = 0 to preserve usage history
    await setAppMonitoredStatus(packageName, false);
  }

  // --- App Rules ---

  Future<List<AppRule>> getAllRules() async {
    final db = await database;
    final maps = await db.query(DatabaseTables.tableAppRules);
    return maps.map(AppRule.fromMap).toList();
  }

  Future<AppRule?> getRule(String packageName) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableAppRules,
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AppRule.fromMap(maps.first);
  }

  Future<void> upsertRule(AppRule rule) async {
    final db = await database;
    await db.insert(
      DatabaseTables.tableAppRules,
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Daily Usage ---

  Future<DailyUsage?> getDailyUsage(String packageName, String dateKey) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableDailyUsage,
      where: 'package_name = ? AND date_key = ?',
      whereArgs: [packageName, dateKey],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DailyUsage.fromMap(maps.first);
  }

  Future<List<DailyUsage>> getDailyUsageForDate(String dateKey) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableDailyUsage,
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    return maps.map(DailyUsage.fromMap).toList();
  }

  Future<List<DailyUsage>> getDailyUsageForDateRange(List<String> dateKeys) async {
    if (dateKeys.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(dateKeys.length, '?').join(',');
    final maps = await db.query(
      DatabaseTables.tableDailyUsage,
      where: 'date_key IN ($placeholders)',
      whereArgs: dateKeys,
    );
    return maps.map(DailyUsage.fromMap).toList();
  }

  Future<void> recordUsageSeconds(
    String packageName,
    String dateKey,
    int deltaSeconds, {
    int defaultAllowanceMinutes = 60,
  }) async {
    if (deltaSeconds <= 0) return;
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        DatabaseTables.tableDailyUsage,
        where: 'package_name = ? AND date_key = ?',
        whereArgs: [packageName, dateKey],
        limit: 1,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      if (existing.isEmpty) {
        await txn.insert(DatabaseTables.tableDailyUsage, {
          'package_name': packageName,
          'date_key': dateKey,
          'accumulated_seconds': deltaSeconds,
          'allowance_minutes': defaultAllowanceMinutes,
          'additional_seconds': 0,
          'updated_at': now,
        });
      } else {
        final currentAccumulated = (existing.first['accumulated_seconds'] as int?) ?? 0;
        await txn.update(
          DatabaseTables.tableDailyUsage,
          {
            'accumulated_seconds': currentAccumulated + deltaSeconds,
            'updated_at': now,
          },
          where: 'package_name = ? AND date_key = ?',
          whereArgs: [packageName, dateKey],
        );
      }
    });
  }

  Future<void> addOverrideSeconds(String packageName, String dateKey, int extraSeconds) async {
    final db = await database;
    final existing = await getDailyUsage(packageName, dateKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing != null) {
      await db.update(
        DatabaseTables.tableDailyUsage,
        {
          'additional_seconds': existing.additionalSeconds + extraSeconds,
          'updated_at': now,
        },
        where: 'package_name = ? AND date_key = ?',
        whereArgs: [packageName, dateKey],
      );
    } else {
      await db.insert(DatabaseTables.tableDailyUsage, {
        'package_name': packageName,
        'date_key': dateKey,
        'accumulated_seconds': 0,
        'allowance_minutes': 60,
        'additional_seconds': extraSeconds,
        'updated_at': now,
      });
    }
  }

  // --- Usage Sessions ---

  Future<void> recordSession({
    required String packageName,
    required DateTime start,
    required DateTime end,
    required int durationSeconds,
    required String source,
  }) async {
    final db = await database;
    await db.insert(DatabaseTables.tableUsageSessions, {
      'package_name': packageName,
      'session_start': start.millisecondsSinceEpoch,
      'session_end': end.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'source': source,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> getSessionCountForApp(String packageName, DateTime start, DateTime end) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM ${DatabaseTables.tableUsageSessions}
      WHERE package_name = ? AND session_start >= ? AND session_end <= ?
      ''',
      [packageName, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // --- Break Sessions ---

  Future<void> createBreakSession(BreakSession session) async {
    final db = await database;
    await db.insert(
      DatabaseTables.tableBreakSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBreakSession(BreakSession session) async {
    final db = await database;
    await db.update(
      DatabaseTables.tableBreakSessions,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<BreakSession?> getActiveBreakSession(String packageName) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableBreakSessions,
      where: 'package_name = ? AND current_state NOT IN (?, ?, ?)',
      whereArgs: [
        packageName,
        BreakState.idle.dbValue,
        BreakState.cancelledOrInvalidated.dbValue,
        BreakState.eligibleToResume.dbValue,
      ],
      orderBy: 'trigger_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BreakSession.fromMap(maps.first);
  }

  Future<List<BreakSession>> getBreakSessions(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableBreakSessions,
      where: 'trigger_time >= ? AND trigger_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'trigger_time DESC',
    );
    return maps.map(BreakSession.fromMap).toList();
  }

  // --- Exercises ---

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final maps = await db.query(DatabaseTables.tableExerciseDefinitions, where: 'is_enabled = 1');
    return maps.map(Exercise.fromMap).toList();
  }

  Future<void> upsertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert(
      DatabaseTables.tableExerciseDefinitions,
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCustomExercise(String id) async {
    final db = await database;
    await db.delete(
      DatabaseTables.tableExerciseDefinitions,
      where: 'id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }

  // --- Exercise Logs ---

  Future<void> logExercise(ExerciseLog log) async {
    final db = await database;
    await db.insert(DatabaseTables.tableExerciseLogs, log.toMap());
  }

  Future<List<ExerciseLog>> getExerciseLogsForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableExerciseLogs,
      where: 'completed_at >= ? AND completed_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'completed_at DESC',
    );
    return maps.map(ExerciseLog.fromMap).toList();
  }

  // --- PIN State ---

  Future<PinState?> getPinState() async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tablePinState,
      where: 'id = 1',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PinState.fromMap(maps.first);
  }

  Future<void> savePinState(PinState pinState) async {
    final db = await database;
    await db.insert(
      DatabaseTables.tablePinState,
      pinState.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Overrides ---

  Future<void> recordOverride(OverrideLog override) async {
    final db = await database;
    await db.insert(DatabaseTables.tableOverrideLogs, override.toMap());
  }

  Future<OverrideLog?> getActiveOverride(String packageName, [DateTime? now]) async {
    final current = now ?? DateTime.now();
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableOverrideLogs,
      where: 'package_name = ? AND expires_at > ?',
      whereArgs: [packageName, current.millisecondsSinceEpoch],
      orderBy: 'expires_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OverrideLog.fromMap(maps.first);
  }

  Future<List<OverrideLog>> getOverridesForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.tableOverrideLogs,
      where: 'authorized_at >= ? AND authorized_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'authorized_at DESC',
    );
    return maps.map(OverrideLog.fromMap).toList();
  }

  // --- Data Management ---

  Future<void> clearHistory() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tableUsageSessions);
      await txn.delete(DatabaseTables.tableDailyUsage);
      await txn.delete(DatabaseTables.tableBreakSessions);
      await txn.delete(DatabaseTables.tableExerciseLogs);
      await txn.delete(DatabaseTables.tableOverrideLogs);
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tableUsageSessions);
      await txn.delete(DatabaseTables.tableDailyUsage);
      await txn.delete(DatabaseTables.tableBreakSessions);
      await txn.delete(DatabaseTables.tableExerciseLogs);
      await txn.delete(DatabaseTables.tableOverrideLogs);
      await txn.delete(DatabaseTables.tableAppRules);
      await txn.delete(DatabaseTables.tableMonitoredApps);
      await txn.delete(DatabaseTables.tablePinState);
      await txn.delete(DatabaseTables.tableUserProfile);
    });
    await _seedDefaultExercises(db);
  }
}
