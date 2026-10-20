import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../platform/native_app_service.dart';
import '../utils/date_utils.dart';
import '../../shared/models/override_log.dart';
import 'pin_service.dart';
import 'break_service.dart';

class UsageMonitorService {
  static UsageMonitorService? _instance;

  final AppDatabase _db;
  final PinService _pinService;
  final BreakService _breakService;
  final DateTime Function() _clock;

  String? _foregroundPackage;
  DateTime? _sessionStartTime;
  int _sessionSeconds = 0;
  Timer? _ticker;

  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  UsageMonitorService._({
    AppDatabase? db,
    PinService? pinService,
    BreakService? breakService,
    DateTime Function()? clock,
  })  : _db = db ?? AppDatabase.instance,
        _pinService = pinService ?? PinService(),
        _breakService = breakService ?? BreakService(),
        _clock = clock ?? DateTime.now;

  static UsageMonitorService get instance {
    _instance ??= UsageMonitorService._();
    return _instance!;
  }

  // Factory for testing
  static UsageMonitorService createForTesting({
    required AppDatabase db,
    required PinService pinService,
    required BreakService breakService,
    DateTime Function()? clock,
  }) {
    return UsageMonitorService._(
      db: db,
      pinService: pinService,
      breakService: breakService,
      clock: clock,
    );
  }

  String? get currentForegroundPackage => _foregroundPackage;
  int get currentSessionSeconds => _sessionSeconds;

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);

    NativeAppService.onForegroundAppChanged = (pkg) {
      handleForegroundChange(pkg);
    };

    // Initial sync
    syncUsageWithGroundTruth();
  }

  void stop() {
    _ticker?.cancel();
  }

  Future<void> handleForegroundChange(String newPackage) async {
    final now = _clock();

    // 1. Flush previous foreground session if monitored
    if (_foregroundPackage != null && _sessionStartTime != null) {
      final elapsed = now.difference(_sessionStartTime!).inSeconds;
      if (elapsed > 0) {
        final prevPkg = _foregroundPackage!;
        final rule = await _db.getRule(prevPkg);
        if (rule != null && rule.isEnabled) {
          final today = EzzeDateUtils.todayKey();
          await _db.recordUsageSeconds(
            prevPkg,
            today,
            elapsed,
            defaultAllowanceMinutes: rule.dailyBudgetMinutes,
          );
          await _db.recordSession(
            packageName: prevPkg,
            start: _sessionStartTime!,
            end: now,
            durationSeconds: elapsed,
            source: 'foreground_monitor',
          );
        }
      }
    }

    // 2. Start new session
    _foregroundPackage = newPackage;
    _sessionStartTime = now;
    _sessionSeconds = 0;

    // 3. Evaluate restriction for new package
    await checkAndEnforceRestrictions(newPackage);
    _updateController.add(null);
  }

  void _onTick(Timer timer) async {
    if (_foregroundPackage == null) return;
    final pkg = _foregroundPackage!;

    final rule = await _db.getRule(pkg);
    if (rule == null || !rule.isEnabled) return;

    _sessionSeconds++;

    // Every 10 seconds, flush accumulated seconds to DB so stats are real-time
    if (_sessionSeconds % 10 == 0) {
      final today = EzzeDateUtils.todayKey();
      await _db.recordUsageSeconds(
        pkg,
        today,
        10,
        defaultAllowanceMinutes: rule.dailyBudgetMinutes,
      );
      _updateController.add(null);
    }

    // Check restrictions
    await checkAndEnforceRestrictions(pkg);
  }

  Future<void> checkAndEnforceRestrictions(String packageName) async {
    final rule = await _db.getRule(packageName);
    if (rule == null || !rule.isEnabled) return;

    final today = EzzeDateUtils.todayKey();
    final daily = await _db.getDailyUsage(packageName, today);
    final accumulatedSeconds = daily?.accumulatedSeconds ?? 0;
    final totalAllowanceSeconds = (daily?.totalAllowanceSeconds ?? (rule.dailyBudgetMinutes * 60));

    // Check for active override
    final now = _clock();
    final activeOverride = await _db.getActiveOverride(packageName, now);

    // 1. Daily limit check
    if (accumulatedSeconds >= totalAllowanceSeconds && activeOverride == null) {
      await NativeAppService.updateRestrictions({packageName: 'limit_over'});
      await NativeAppService.triggerRestriction(packageName, 'limit_over');
      return;
    }

    // 2. Continuous session break check
    final sessionLimitSeconds = rule.sessionLimitMinutes * 60;
    if (_sessionSeconds >= sessionLimitSeconds) {
      // Require break session
      await _breakService.requireBreak(
        packageName: packageName,
        breakDurationSeconds: rule.breakDurationMinutes * 60,
      );
      await NativeAppService.updateRestrictions({packageName: 'break'});
      await NativeAppService.triggerRestriction(packageName, 'break');
      return;
    }
  }

  /// Authorizes an explicit daily limit override with 8-digit PIN validation
  Future<bool> authorizeOverride({
    required String packageName,
    required int extensionMinutes,
    required String pin,
  }) async {
    final isValid = await _pinService.validatePin(pin);
    if (!isValid) return false;

    final rule = await _db.getRule(packageName);
    final today = EzzeDateUtils.todayKey();
    final daily = await _db.getDailyUsage(packageName, today);

    final now = _clock();
    final expiresAt = now.add(Duration(minutes: extensionMinutes));

    final override = OverrideLog(
      packageName: packageName,
      originalBudgetMinutes: rule?.dailyBudgetMinutes ?? 60,
      usageAtAuthSeconds: daily?.accumulatedSeconds ?? 0,
      extensionMinutes: extensionMinutes,
      authorizedAt: now,
      expiresAt: expiresAt,
    );

    await _db.recordOverride(override);
    await _db.addOverrideSeconds(packageName, today, extensionMinutes * 60);

    // Clear restriction
    await NativeAppService.updateRestrictions({});
    _updateController.add(null);
    return true;
  }

  /// Releases a break after valid exercise completion and PIN verification
  Future<void> releaseBreak(String packageName) async {
    _sessionSeconds = 0;
    _sessionStartTime = _clock();
    await NativeAppService.updateRestrictions({});
    _updateController.add(null);
  }

  /// Syncs daily usage from Android's UsageStatsManager ground truth
  Future<void> syncUsageWithGroundTruth() async {
    try {
      final now = _clock();
      final startOfDay = EzzeDateUtils.startOfDay(now).millisecondsSinceEpoch;
      final endOfDay = now.millisecondsSinceEpoch;

      final nativeStats = await NativeAppService.getUsageStats(startOfDay, endOfDay);
      final monitoredApps = await _db.getAllMonitoredApps(activeOnly: true);
      final today = EzzeDateUtils.todayKey();

      for (final app in monitoredApps) {
        final groundTruthMillis = nativeStats[app.packageName];
        if (groundTruthMillis != null && groundTruthMillis > 0) {
          final groundTruthSeconds = (groundTruthMillis / 1000).round();
          final current = await _db.getDailyUsage(app.packageName, today);
          if (current == null || current.accumulatedSeconds < groundTruthSeconds) {
            final diff = groundTruthSeconds - (current?.accumulatedSeconds ?? 0);
            final rule = await _db.getRule(app.packageName);
            if (diff > 0) {
              await _db.recordUsageSeconds(
                app.packageName,
                today,
                diff,
                defaultAllowanceMinutes: rule?.dailyBudgetMinutes ?? 60,
              );
            }
          }
        }
      }
      _updateController.add(null);
    } catch (e) {
      debugPrint('Sync usage error: $e');
    }
  }
}
