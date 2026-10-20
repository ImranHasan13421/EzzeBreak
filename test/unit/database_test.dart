import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_break/core/database/app_database.dart';
import 'package:ezze_break/core/services/report_service.dart';
import 'package:ezze_break/shared/models/app_rule.dart';
import 'package:ezze_break/shared/models/exercise.dart';
import 'package:ezze_break/shared/models/exercise_log.dart';
import 'package:ezze_break/shared/models/monitored_app.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = await setupTestDatabase();
    await db.clearAllData();
  });

  group('AppDatabase and ReportService Tests', () {
    test('Monitored apps CRUD operations', () async {
      final app = MonitoredApp(
        packageName: 'com.test.app',
        appName: 'Test App',
        isMonitored: true,
      );
      await db.upsertMonitoredApp(app);

      final retrieved = await db.getMonitoredApp('com.test.app');
      expect(retrieved, isNotNull);
      expect(retrieved!.appName, 'Test App');
      expect(retrieved.isMonitored, isTrue);

      await db.setAppMonitoredStatus('com.test.app', false);
      final paused = await db.getMonitoredApp('com.test.app');
      expect(paused!.isMonitored, isFalse);

      final all = await db.getAllMonitoredApps();
      expect(all.length, 1);
    });

    test('App rules persistence and retrieval', () async {
      final rule = AppRule(
        packageName: 'com.test.app',
        dailyBudgetMinutes: 90,
        sessionLimitMinutes: 25,
        breakDurationMinutes: 10,
        exerciseIds: ['pushups', 'squats'],
      );
      await db.upsertRule(rule);

      final fetched = await db.getRule('com.test.app');
      expect(fetched, isNotNull);
      expect(fetched!.dailyBudgetMinutes, 90);
      expect(fetched.sessionLimitMinutes, 25);
      expect(fetched.breakDurationMinutes, 10);
      expect(fetched.exerciseIds, ['pushups', 'squats']);
    });

    test('Exercises CRUD and logs', () async {
      final custom = Exercise(
        id: 'wall_sit',
        name: 'Wall Sit',
        type: ExerciseType.durationSeconds,
        defaultTarget: 60,
        isCustom: true,
      );
      await db.upsertExercise(custom);

      final all = await db.getAllExercises();
      expect(all.any((e) => e.id == 'wall_sit'), isTrue);

      final log = ExerciseLog(
        exerciseId: 'wall_sit',
        exerciseName: 'Wall Sit',
        durationSeconds: 60,
        completedAt: DateTime.now(),
      );
      await db.logExercise(log);

      final logs = await db.getExerciseLogsForDateRange(
        DateTime.now().subtract(const Duration(hours: 1)),
        DateTime.now().add(const Duration(hours: 1)),
      );
      expect(logs.length, 1);
      expect(logs.first.exerciseName, 'Wall Sit');

      await db.deleteCustomExercise('wall_sit');
      final remaining = await db.getAllExercises();
      expect(remaining.any((e) => e.id == 'wall_sit'), isFalse);
    });

    test('ReportService computes accurate 7-day analytics and builds PDF', () async {
      await db.upsertMonitoredApp(MonitoredApp(
        packageName: 'com.video.tube',
        appName: 'Tube Player',
      ));
      await db.upsertRule(AppRule(
        packageName: 'com.video.tube',
        dailyBudgetMinutes: 60,
      ));

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));

      // Record usage for today
      await db.recordUsageSeconds('com.video.tube', '2026-10-20', 3600);
      await db.logExercise(ExerciseLog(
        exerciseId: 'pushups',
        exerciseName: 'Push-ups',
        repetitions: 25,
        completedAt: now,
      ));

      final reportService = ReportService(db);
      final summary = await reportService.getAnalyticsForDateRange(start, now, '7-Day Report');

      expect(summary.totalUsageSeconds, 3600);
      expect(summary.monitoredAppsCount, 1);
      expect(summary.totalRepetitions, 25);
      expect(summary.appStats.length, 1);
      expect(summary.appStats.first.appName, 'Tube Player');

      final pdfBytes = await reportService.generatePdfReport(summary);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF header verification
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });

    test('clearHistory and clearAllData work properly', () async {
      await db.recordUsageSeconds('com.test.app', '2026-10-20', 1200);
      await db.clearHistory();

      final daily = await db.getDailyUsage('com.test.app', '2026-10-20');
      expect(daily, isNull);
    });
  });
}
