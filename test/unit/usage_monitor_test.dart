import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_break/core/database/app_database.dart';
import 'package:ezze_break/core/services/break_service.dart';
import 'package:ezze_break/core/services/pin_service.dart';
import 'package:ezze_break/core/services/usage_monitor_service.dart';
import 'package:ezze_break/core/utils/date_utils.dart';
import 'package:ezze_break/shared/models/app_rule.dart';
import 'package:ezze_break/shared/models/monitored_app.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PinService pinService;
  late BreakService breakService;
  late UsageMonitorService usageMonitor;
  late DateTime simulatedTime;

  DateTime getClock() => simulatedTime;

  setUp(() async {
    db = await setupTestDatabase();
    simulatedTime = DateTime(2026, 10, 20, 10, 0, 0);
    pinService = PinService(db: db, clock: getClock);
    breakService = BreakService(db: db, pinService: pinService, clock: getClock);
    usageMonitor = UsageMonitorService.createForTesting(
      db: db,
      pinService: pinService,
      breakService: breakService,
      clock: getClock,
    );

    await db.clearAllData();
    // Seed monitored app with 60m budget, 20m continuous session limit
    await db.upsertMonitoredApp(MonitoredApp(
      packageName: 'com.social.app',
      appName: 'Social App',
    ));
    await db.upsertRule(AppRule(
      packageName: 'com.social.app',
      dailyBudgetMinutes: 60,
      sessionLimitMinutes: 20,
      breakDurationMinutes: 5,
    ));
  });

  group('UsageMonitorService Accounting and Enforcement Tests', () {
    test('Foreground transition accumulates usage and records session', () async {
      await usageMonitor.handleForegroundChange('com.social.app');
      expect(usageMonitor.currentForegroundPackage, 'com.social.app');
      expect(usageMonitor.currentSessionSeconds, 0);

      // Advance clock by 15 minutes (900 seconds)
      simulatedTime = simulatedTime.add(const Duration(minutes: 15));

      // Switch away to home launcher
      await usageMonitor.handleForegroundChange('com.android.launcher');

      final today = EzzeDateUtils.dateKey(simulatedTime);
      final daily = await db.getDailyUsage('com.social.app', today);
      expect(daily, isNotNull);
      expect(daily!.accumulatedSeconds, 900);
      expect(daily.isOverBudget, isFalse);
    });

    test('Break release resets continuous session without erasing daily accumulated usage', () async {
      // 1. App in foreground for 15 minutes
      await usageMonitor.handleForegroundChange('com.social.app');
      simulatedTime = simulatedTime.add(const Duration(minutes: 15));
      await usageMonitor.handleForegroundChange('com.android.launcher');

      final today = EzzeDateUtils.dateKey(simulatedTime);
      var daily = await db.getDailyUsage('com.social.app', today);
      expect(daily!.accumulatedSeconds, 900);

      // 2. User completes a break
      await usageMonitor.releaseBreak('com.social.app');
      expect(usageMonitor.currentSessionSeconds, 0);

      // 3. User launches app again for another 10 minutes
      await usageMonitor.handleForegroundChange('com.social.app');
      simulatedTime = simulatedTime.add(const Duration(minutes: 10));
      await usageMonitor.handleForegroundChange('com.android.launcher');

      daily = await db.getDailyUsage('com.social.app', today);
      // Daily usage should have accumulated (900 + 600 = 1500 seconds)
      expect(daily!.accumulatedSeconds, 1500);
    });

    test('Daily limit exhaustion triggers restriction', () async {
      final today = EzzeDateUtils.dateKey(simulatedTime);
      // Pre-record 65 minutes of usage on a 60-minute budget
      await db.recordUsageSeconds('com.social.app', today, 3900, defaultAllowanceMinutes: 60);

      final daily = await db.getDailyUsage('com.social.app', today);
      expect(daily!.isOverBudget, isTrue);
    });

    test('Authorize override with valid PIN extends daily budget', () async {
      final pinState = await pinService.getCurrentPinState();
      final today = EzzeDateUtils.dateKey(simulatedTime);

      // Pre-record 60 minutes
      await db.recordUsageSeconds('com.social.app', today, 3600, defaultAllowanceMinutes: 60);

      // Authorize 15-minute override
      final authorized = await usageMonitor.authorizeOverride(
        packageName: 'com.social.app',
        extensionMinutes: 15,
        pin: pinState.currentPin,
      );
      expect(authorized, isTrue);

      final daily = await db.getDailyUsage('com.social.app', today);
      expect(daily!.additionalSeconds, 15 * 60);
      expect(daily.totalAllowanceSeconds, (60 + 15) * 60);
      expect(daily.isOverBudget, isFalse);

      final override = await db.getActiveOverride('com.social.app', simulatedTime);
      expect(override, isNotNull);
      expect(override!.extensionMinutes, 15);
      expect(override.isExpired(simulatedTime), isFalse);

      // Advance clock past extension
      simulatedTime = simulatedTime.add(const Duration(minutes: 16));
      expect(override.isExpired(simulatedTime), isTrue);
    });
  });
}
