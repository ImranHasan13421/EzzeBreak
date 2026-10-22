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

    NativeAppService.onUsageTick = (pkg, dailySec, sessionSec) async {
      final today = EzzeDateUtils.todayKey();
      final current = await _db.getDailyUsage(pkg, today);
      final delta = dailySec - (current?.accumulatedSeconds ?? 0);
      if (delta > 0) {
        final rule = await _db.getRule(pkg);
        await _db.recordUsageSeconds(
          pkg,
          today,
          delta,
          defaultAllowanceMinutes: rule?.dailyBudgetMinutes ?? 60,
        );
        _updateController.add(null);
      }
    };

    // Initial sync of rules and state with native tracking
    syncRulesToNative();
    pullUsageFromNative();
  }

  void stop() {
    _ticker?.cancel();
  }

  Future<void> syncRulesToNative() async {
    try {
      final apps = await _db.getAllMonitoredApps();
      final now = _clock();
      final today = EzzeDateUtils.dateKey(now);
      final rulesPayload = <Map<String, dynamic>>[];
      for (final app in apps) {
        final rule = await _db.getRule(app.packageName);
        final daily = await _db.getDailyUsage(app.packageName, today);
        rulesPayload.add({
          'packageName': app.packageName,
          'sessionLimitMinutes': rule?.sessionLimitMinutes ?? 20,
          'dailyBudgetMinutes': rule?.dailyBudgetMinutes ?? 60,
          'breakDurationMinutes': rule?.breakDurationMinutes ?? 5,
          'additionalSeconds': daily?.additionalSeconds ?? 0,
          'isMonitored': app.isMonitored,
        });
      }
      await NativeAppService.syncRules(rulesPayload);
    } catch (e) {
      debugPrint('Error syncing rules to native: $e');
    }
  }

  Future<void> pullUsageFromNative() async {
    try {
      final nativeUsage = await NativeAppService.getNativeUsage();
      final now = _clock();
      final today = EzzeDateUtils.dateKey(now);
      for (final entry in nativeUsage.entries) {
        final pkg = entry.key;
        final sec = entry.value;
        final current = await _db.getDailyUsage(pkg, today);
        final currentSec = current?.accumulatedSeconds ?? 0;
        if (sec > currentSec) {
          final rule = await _db.getRule(pkg);
          await _db.recordUsageSeconds(
            pkg,
            today,
            sec - currentSec,
            defaultAllowanceMinutes: rule?.dailyBudgetMinutes ?? 60,
          );
        } else if (currentSec > sec) {
          await NativeAppService.setNativeUsage(pkg, currentSec);
        }
      }
      _updateController.add(null);
    } catch (e) {
      debugPrint('Error pulling native usage: $e');
    }
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
          final today = EzzeDateUtils.dateKey(now);
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
    final now = _clock();
    if (_sessionSeconds % 10 == 0) {
      final today = EzzeDateUtils.dateKey(now);
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

    final now = _clock();
    final today = EzzeDateUtils.dateKey(now);
    final daily = await _db.getDailyUsage(packageName, today);
    final accumulatedSeconds = daily?.accumulatedSeconds ?? 0;
    final totalAllowanceSeconds = (daily?.totalAllowanceSeconds ?? (rule.dailyBudgetMinutes * 60));

    // Check for active override
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

    final now = _clock();
    final rule = await _db.getRule(packageName);
    final today = EzzeDateUtils.dateKey(now);
    final daily = await _db.getDailyUsage(packageName, today);

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

    // Update native with extra time and clear limit restriction
    await NativeAppService.grantOverride(packageName, extensionMinutes * 60);
    _updateController.add(null);
    return true;
  }

  /// Releases a break after valid exercise completion and PIN verification
  Future<void> releaseBreak(String packageName) async {
    _sessionSeconds = 0;
    _sessionStartTime = _clock();
    await NativeAppService.releaseBreak(packageName);
    _updateController.add(null);
  }

  /// Pulls live usage from Ezze's native internal tracker (independent from Android Digital Wellbeing)
  Future<void> syncUsageWithGroundTruth() async {
    await pullUsageFromNative();
    await syncRulesToNative();
  }
}
