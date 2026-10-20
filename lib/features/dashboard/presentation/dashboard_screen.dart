import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/circular_usage_gauge.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app_management/presentation/app_selector_sheet.dart';
import '../../app_rules/presentation/rule_config_screen.dart';
import '../../breaks/presentation/break_screen.dart';
import '../../exercises/presentation/exercise_library_screen.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../overrides/presentation/override_dialog.dart';
import '../../pin_management/presentation/show_pin_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/providers/theme_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _breaksDoneToday = 0;
  int _breaksTriggeredToday = 0;
  int _exercisesDoneToday = 0;
  int _overridesToday = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyStats();
    _checkPendingNativeAction();
  }

  void _checkPendingNativeAction() async {
    final pending = await NativeAppService.getPendingAction();
    if (pending != null && mounted) {
      final action = pending['action'];
      final pkg = pending['packageName'] ?? '';
      if (action == 'START_BREAK' && pkg.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BreakScreen(packageName: pkg)),
        );
      } else if (action == 'START_OVERRIDE' && pkg.isNotEmpty) {
        final db = ref.read(databaseProvider);
        final app = await db.getMonitoredApp(pkg);
        final rule = await db.getRule(pkg);
        final daily = await db.getDailyUsage(pkg, EzzeDateUtils.todayKey());
        if (app != null && mounted) {
          showDialog(
            context: context,
            builder: (_) => OverrideDialog(
              app: app,
              usageSeconds: daily?.accumulatedSeconds ?? 0,
              budgetMinutes: rule?.dailyBudgetMinutes ?? 60,
            ),
          );
        }
      }
    }
  }

  void _loadDailyStats() async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now();
    final start = EzzeDateUtils.startOfDay(today);
    final end = EzzeDateUtils.endOfDay(today);

    final breaks = await db.getBreakSessions(start, end);
    final exercises = await db.getExerciseLogsForDateRange(start, end);
    final overrides = await db.getOverridesForDateRange(start, end);

    if (mounted) {
      setState(() {
        _breaksTriggeredToday = breaks.length;
        _breaksDoneToday = breaks.where((b) => b.completedTime != null).length;
        _exercisesDoneToday = exercises.length;
        _overridesToday = overrides.length;
      });
    }
  }

  void _openAppSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSelectorSheet(),
    ).then((_) {
      ref.read(monitoredAppsListProvider.notifier).loadApps();
      ref.read(todayUsageProvider.notifier).refresh();
      _loadDailyStats();
    });
  }

  void _showAppContextMenu(MonitoredApp app, int usedSec, int budgetMins) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
            border: Border.all(
              color: isDark ? AppColors.darkGlassStroke : AppColors.lightBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppIconView(
                  base64Icon: app.iconBase64,
                  fallbackLetter: app.appName,
                  size: 36,
                ),
                title: Text(app.appName, style: AppTypography.titleLarge),
                subtitle: Text(
                  '${Formatters.formatSeconds(usedSec)} used today',
                  style: AppTypography.bodySmall,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: AppColors.brandRed),
                title: const Text('Configure Rules'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RuleConfigScreen(app: app),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_filled_rounded, color: AppColors.accentGreen),
                title: const Text('Start Active Break Now'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BreakScreen(packageName: app.packageName),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open_rounded, color: AppColors.accentAmber),
                title: const Text('Request Override'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => OverrideDialog(
                      app: app,
                      usageSeconds: usedSec,
                      budgetMinutes: budgetMins,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayUsageProvider, (_, _) {
      _loadDailyStats();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final displayName = ref.watch(profileNameProvider);
    final perms = ref.watch(permissionsProvider);
    final apps = ref.watch(monitoredAppsListProvider);
    final rules = ref.watch(appRulesMapProvider);
    final todayUsages = ref.watch(todayUsageProvider);

    int totalSecondsToday = 0;
    int totalBudgetMinutes = 0;

    for (final app in apps.where((a) => a.isMonitored)) {
      final usage = todayUsages[app.packageName];
      if (usage != null) {
        totalSecondsToday += usage.accumulatedSeconds;
      }
      final rule = rules[app.packageName];
      totalBudgetMinutes += rule?.dailyBudgetMinutes ?? 60;
    }

    if (totalBudgetMinutes == 0) {
      totalBudgetMinutes = 180; // default 3 hours fallback
    }

    final totalMinutesToday = totalSecondsToday ~/ 60;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandRed,
          onRefresh: () async {
            await ref.read(monitoredAppsListProvider.notifier).loadApps();
            await ref.read(todayUsageProvider.notifier).refresh();
            await ref.read(permissionsProvider.notifier).checkAll();
            await ref.read(usageMonitorServiceProvider).syncUsageWithGroundTruth();
            _loadDailyStats();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandRed.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          child: Image.asset(
                            'assets/logo/applogo.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EZZE BREAK',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.brandRed,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            displayName.isNotEmpty ? 'Hello, $displayName' : 'Mindful Dashboard',
                            style: AppTypography.titleLarge.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.pin_outlined, size: 22),
                        tooltip: 'Show PIN',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShowPinScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded, size: 22),
                        tooltip: 'Profile',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                EzzeDateUtils.formatPretty(DateTime.now()),
                style: AppTypography.bodySmall.copyWith(color: secondaryText),
              ),
              const SizedBox(height: Spacing.lg),

              // Permissions Incomplete Warning Banner
              if (!perms.isFullyConfigured) ...[
                EzzeCard.status(
                  statusColor: AppColors.accentAmber,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.accentAmber, size: 28),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions Incomplete',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Usage access or accessibility service needed for active enforcement.',
                              style: AppTypography.bodySmall.copyWith(color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: const Text('Configure'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],

              // Hero Circular Usage Gauge Card
              EzzeCard(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Screen Budget',
                          style: AppTypography.titleSmall.copyWith(color: secondaryText),
                        ),
                        StatusBadge(
                          label: '${apps.where((a) => a.isMonitored).length} Active',
                          type: apps.any((a) => a.isMonitored) ? BadgeType.active : BadgeType.neutral,
                          showDot: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    CircularUsageGauge(
                      usedMinutes: totalMinutesToday,
                      budgetMinutes: totalBudgetMinutes,
                      size: 190,
                      strokeWidth: 12,
                    ),
                    const SizedBox(height: Spacing.xl),
                    const Divider(),
                    const SizedBox(height: Spacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          'Breaks Done',
                          '$_breaksDoneToday / $_breaksTriggeredToday',
                          Icons.pause_circle_outline_rounded,
                        ),
                        _buildQuickStat(
                          'Exercises',
                          '$_exercisesDoneToday',
                          Icons.fitness_center_rounded,
                        ),
                        _buildQuickStat(
                          'Overrides',
                          '$_overridesToday',
                          Icons.lock_open_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Quick Action Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionChip(
                      icon: Icons.add_rounded,
                      label: 'Add App',
                      onTap: _openAppSelector,
                    ),
                    const SizedBox(width: Spacing.sm),
                    _buildActionChip(
                      icon: Icons.pin_rounded,
                      label: 'Daily PIN',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShowPinScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: Spacing.sm),
                    _buildActionChip(
                      icon: Icons.fitness_center_rounded,
                      label: 'Exercises',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: Spacing.sm),
                    _buildActionChip(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Export PDF',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xxl),

              // Monitored Applications Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monitored Applications',
                    style: AppTypography.headlineSmall.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (apps.isNotEmpty)
                    TextButton.icon(
                      onPressed: _openAppSelector,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Monitored App List or Empty State
              if (apps.isEmpty) ...[
                EzzeCard(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.apps_rounded, size: 48, color: AppColors.brandRed),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        'Start Monitoring Your Habits',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Choose the apps you spend the most time on. Ezze Break will enforce mindful continuous session breaks and daily limits.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: Spacing.xl),
                      EzzeButton(
                        text: 'Add First Monitored App',
                        icon: Icons.add_rounded,
                        onPressed: _openAppSelector,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...apps.map((app) {
                  final rule = rules[app.packageName];
                  final daily = todayUsages[app.packageName];
                  final usedSec = daily?.accumulatedSeconds ?? 0;
                  final budgetMins = rule?.dailyBudgetMinutes ?? 60;
                  final sessionMins = rule?.sessionLimitMinutes ?? 20;
                  final isOver = daily?.isOverBudget ?? false;
                  final ratio = (daily?.usageRatio ?? 0.0).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: EzzeCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RuleConfigScreen(app: app, initialRule: rule),
                          ),
                        );
                      },
                      onLongPress: () => _showAppContextMenu(app, usedSec, budgetMins),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AppIconView(
                                base64Icon: app.iconBase64,
                                fallbackLetter: app.appName,
                                size: 46,
                              ),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.appName,
                                      style: AppTypography.titleLarge.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${Formatters.formatSeconds(usedSec)} of ${Formatters.formatMinutes(budgetMins)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isOver ? AppColors.error : secondaryText,
                                        fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: app.isMonitored,
                                activeThumbColor: AppColors.brandRed,
                                onChanged: (val) {
                                  ref
                                      .read(monitoredAppsListProvider.notifier)
                                      .toggleMonitoring(app.packageName, val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.md),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.xs),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? AppColors.error
                                    : (ratio > 0.75 ? AppColors.warning : AppColors.brandRed),
                              ),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Break every ${sessionMins}m',
                                style: AppTypography.bodySmall.copyWith(color: secondaryText),
                              ),
                              if (isOver)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => OverrideDialog(
                                        app: app,
                                        usageSeconds: usedSec,
                                        budgetMinutes: budgetMins,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Limit Reached • Override',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '${Formatters.formatMinutes(budgetMins - (usedSec ~/ 60))} remaining',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.brandRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: Spacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.brandRed),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkGlassStroke : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.full),
        side: BorderSide(color: border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.brandRed),
              const SizedBox(width: Spacing.xs),
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
