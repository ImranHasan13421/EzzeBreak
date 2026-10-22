import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../core/services/break_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/services/usage_monitor_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/models/app_rule.dart';
import '../../../shared/models/daily_usage.dart';
import '../../../shared/models/pin_state.dart';
import '../../../shared/models/break_session.dart';

// Services
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);
final pinServiceProvider = Provider<PinService>((ref) => PinService(db: ref.watch(databaseProvider)));
final breakServiceProvider = Provider<BreakService>((ref) => BreakService(
  db: ref.watch(databaseProvider),
  pinService: ref.watch(pinServiceProvider),
));
final usageMonitorServiceProvider = Provider<UsageMonitorService>((ref) => UsageMonitorService.instance);

// Permissions Model
class PermissionsState {
  final bool hasUsageAccess;
  final bool hasOverlay;
  final bool hasAccessibility;
  final bool hasNotification;

  const PermissionsState({
    this.hasUsageAccess = false,
    this.hasOverlay = false,
    this.hasAccessibility = false,
    this.hasNotification = false,
  });

  bool get isFullyConfigured =>
      hasUsageAccess && hasOverlay && hasAccessibility;

  PermissionsState copyWith({
    bool? hasUsageAccess,
    bool? hasOverlay,
    bool? hasAccessibility,
    bool? hasNotification,
  }) {
    return PermissionsState(
      hasUsageAccess: hasUsageAccess ?? this.hasUsageAccess,
      hasOverlay: hasOverlay ?? this.hasOverlay,
      hasAccessibility: hasAccessibility ?? this.hasAccessibility,
      hasNotification: hasNotification ?? this.hasNotification,
    );
  }
}

// Permissions Notifier
final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(const PermissionsState()) {
    checkAll();
  }

  Future<void> checkAll() async {
    final usage = await NativeAppService.checkUsagePermission();
    final overlay = await NativeAppService.checkOverlayPermission();
    final accessibility = await NativeAppService.checkAccessibilityPermission();
    final notif = await NativeAppService.checkNotificationPermission();

    state = PermissionsState(
      hasUsageAccess: usage,
      hasOverlay: overlay,
      hasAccessibility: accessibility,
      hasNotification: notif,
    );
  }
}

// Monitored Apps Notifier
final monitoredAppsListProvider = StateNotifierProvider<MonitoredAppsNotifier, List<MonitoredApp>>((ref) {
  final db = ref.watch(databaseProvider);
  return MonitoredAppsNotifier(db);
});

class MonitoredAppsNotifier extends StateNotifier<List<MonitoredApp>> {
  final AppDatabase _db;

  MonitoredAppsNotifier(this._db) : super([]) {
    loadApps();
  }

  Future<void> loadApps() async {
    final apps = await _db.getAllMonitoredApps();
    if (!mounted) return;
    state = apps;
  }

  Future<void> addApp(MonitoredApp app, AppRule rule) async {
    await _db.upsertMonitoredApp(app);
    await _db.upsertRule(rule);
    await loadApps();
    await UsageMonitorService.instance.syncRulesToNative();
  }

  Future<void> toggleMonitoring(String packageName, bool isMonitored) async {
    await _db.setAppMonitoredStatus(packageName, isMonitored);
    await loadApps();
    await UsageMonitorService.instance.syncRulesToNative();
  }

  Future<void> removeApp(String packageName) async {
    await _db.removeMonitoredApp(packageName);
    await loadApps();
    await UsageMonitorService.instance.syncRulesToNative();
  }
}

// App Rules Notifier
final appRulesMapProvider = StateNotifierProvider<AppRulesNotifier, Map<String, AppRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return AppRulesNotifier(db);
});

class AppRulesNotifier extends StateNotifier<Map<String, AppRule>> {
  final AppDatabase _db;

  AppRulesNotifier(this._db) : super({}) {
    loadRules();
  }

  Future<void> loadRules() async {
    final rules = await _db.getAllRules();
    if (!mounted) return;
    state = {for (final r in rules) r.packageName: r};
  }

  Future<void> saveRule(AppRule rule) async {
    await _db.upsertRule(rule);
    if (!mounted) return;
    state = {...state, rule.packageName: rule};
    await UsageMonitorService.instance.syncRulesToNative();
  }
}

// Today's Daily Usage Map Notifier
final todayUsageProvider = StateNotifierProvider<TodayUsageNotifier, Map<String, DailyUsage>>((ref) {
  final db = ref.watch(databaseProvider);
  final monitor = ref.watch(usageMonitorServiceProvider);
  return TodayUsageNotifier(db, monitor);
});

class TodayUsageNotifier extends StateNotifier<Map<String, DailyUsage>> {
  final AppDatabase _db;
  final UsageMonitorService _monitor;
  dynamic _sub;

  TodayUsageNotifier(this._db, this._monitor) : super({}) {
    refresh();
    _sub = _monitor.onUpdate.listen((_) {
      refresh();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final today = EzzeDateUtils.todayKey();
    final usages = await _db.getDailyUsageForDate(today);
    if (!mounted) return;
    state = {for (final u in usages) u.packageName: u};
  }
}

// PIN State Provider
final pinStateNotifierProvider = StateNotifierProvider<PinStateNotifier, AsyncValue<PinState>>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  return PinStateNotifier(pinService);
});

class PinStateNotifier extends StateNotifier<AsyncValue<PinState>> {
  final PinService _pinService;

  PinStateNotifier(this._pinService) : super(const AsyncValue.loading()) {
    loadPin();
  }

  Future<void> loadPin() async {
    try {
      final pin = await _pinService.getCurrentPinState();
      state = AsyncValue.data(pin);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rotatePin() async {
    try {
      state = const AsyncValue.loading();
      final pin = await _pinService.rotatePinNow();
      state = AsyncValue.data(pin);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Active Break Session Provider
final activeBreakNotifierProvider = StateNotifierProvider<ActiveBreakNotifier, BreakSession?>((ref) {
  final breakService = ref.watch(breakServiceProvider);
  return ActiveBreakNotifier(breakService);
});

class ActiveBreakNotifier extends StateNotifier<BreakSession?> {
  final BreakService _breakService;

  ActiveBreakNotifier(this._breakService) : super(null);

  void setActiveBreak(BreakSession session) {
    state = session;
  }

  void clearActiveBreak() {
    state = null;
  }

  Future<void> checkActiveBreak(String packageName) async {
    state = await _breakService.getActiveBreak(packageName);
  }
}
