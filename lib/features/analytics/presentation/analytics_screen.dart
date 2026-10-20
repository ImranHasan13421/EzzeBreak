import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/services/report_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/analytics_summary.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../reports/presentation/reports_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedFilter = 0; // 0: Today, 1: Yesterday, 2: Last 7 Days
  AnalyticsSummary? _summary;
  bool _isLoading = true;

  final List<String> _filters = ['Today', 'Yesterday', 'Last 7 Days'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final reportService = ReportService(db);
    final now = DateTime.now();

    DateTime start;
    DateTime end;
    String title;

    switch (_selectedFilter) {
      case 1:
        start = now.subtract(const Duration(days: 1));
        end = now.subtract(const Duration(days: 1));
        title = 'Yesterday (${EzzeDateUtils.formatPretty(start)})';
        break;
      case 2:
        start = now.subtract(const Duration(days: 6));
        end = now;
        title = 'Last 7 Days';
        break;
      case 0:
      default:
        start = now;
        end = now;
        title = 'Today (${EzzeDateUtils.formatPretty(now)})';
        break;
    }

    final data = await reportService.getAnalyticsForDateRange(start, end, title);
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayUsageProvider, (_, _) {
      _loadAnalytics();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final totalBreaks = _summary?.breaksTriggered ?? 0;
    final completedBreaks = _summary?.breaksCompleted ?? 0;
    final complianceRate = totalBreaks > 0
        ? ((completedBreaks / totalBreaks) * 100).round()
        : 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Insights & Analytics',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandRed))
          : RefreshIndicator(
              color: AppColors.brandRed,
              onRefresh: () async => _loadAnalytics(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
                children: [
                  // Period Selector Chips
                  Row(
                    children: List.generate(_filters.length, (index) {
                      final isSel = _selectedFilter == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: Spacing.sm),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedFilter = index);
                            _loadAnalytics();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.brandRed
                                  : (isDark ? AppColors.darkBg2 : AppColors.lightBg2),
                              borderRadius: BorderRadius.circular(Radii.full),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.brandRed
                                    : (isDark ? AppColors.darkGlassStroke : AppColors.lightBorder),
                              ),
                            ),
                            child: Text(
                              _filters[index],
                              style: AppTypography.labelMedium.copyWith(
                                color: isSel ? Colors.white : secondaryText,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Overview Summary Card
                  EzzeCard(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Screen Time', style: AppTypography.titleSmall.copyWith(color: secondaryText)),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          Formatters.formatSeconds(_summary?.totalUsageSeconds ?? 0),
                          style: AppTypography.mono.copyWith(
                            fontSize: 32,
                            color: AppColors.brandRed,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        const Divider(),
                        const SizedBox(height: Spacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('Breaks Done', '$completedBreaks / $totalBreaks'),
                            _buildStatColumn('Exercises', '${_summary?.exercisesCompleted ?? 0} logged'),
                            _buildStatColumn('Overrides', '${_summary?.overridesCount ?? 0} count'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // Break Compliance Section
                  _buildSectionHeader('Break Compliance', 'Consistency in taking active rest breaks.'),
                  const SizedBox(height: Spacing.sm),
                  EzzeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Compliance Rate',
                              style: AppTypography.titleSmall.copyWith(color: secondaryText),
                            ),
                            Text(
                              '$complianceRate%',
                              style: AppTypography.titleLarge.copyWith(
                                color: complianceRate >= 70
                                    ? AppColors.accentGreen
                                    : (complianceRate >= 50
                                        ? AppColors.accentAmber
                                        : AppColors.error),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.xs),
                          child: LinearProgressIndicator(
                            value: (complianceRate / 100.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              complianceRate >= 70
                                  ? AppColors.accentGreen
                                  : (complianceRate >= 50
                                      ? AppColors.accentAmber
                                      : AppColors.error),
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          '$completedBreaks of $totalBreaks breaks completed with exercise.',
                          style: AppTypography.bodySmall.copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // 7-Day Usage Trend
                  if (_selectedFilter == 2 && (_summary?.dailyTrends ?? []).isNotEmpty) ...[
                    _buildSectionHeader('7-Day Daily Trend', 'Daily screen time comparison across the week.'),
                    const SizedBox(height: Spacing.sm),
                    EzzeCard(
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxDailyTrend(),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => isDark ? AppColors.darkBg3 : AppColors.lightBg2,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final mins = rod.toY.round();
                                  return BarTooltipItem(
                                    Formatters.formatMinutes(mins),
                                    AppTypography.bodySmall.copyWith(
                                      color: primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < (_summary?.dailyTrends.length ?? 0)) {
                                      final item = _summary!.dailyTrends[idx];
                                      final date = EzzeDateUtils.parseDateKey(item.dateKey);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          EzzeDateUtils.formatWeekday(date),
                                          style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 60,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(_summary!.dailyTrends.length, (i) {
                              final trend = _summary!.dailyTrends[i];
                              final mins = trend.usageSeconds / 60.0;
                              final isToday = i == _summary!.dailyTrends.length - 1;

                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: mins,
                                    gradient: isToday
                                        ? const LinearGradient(
                                            colors: [AppColors.brandRed, AppColors.brandRedLight],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              AppColors.brandRed.withValues(alpha: 0.45),
                                              AppColors.brandRedLight.withValues(alpha: 0.45),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                    width: 18,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xs)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: _getMaxDailyTrend(),
                                      color: (isDark ? AppColors.darkBg3 : AppColors.lightBg3).withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],

                  // Donut Chart: App Usage Distribution
                  if ((_summary?.totalUsageSeconds ?? 0) > 0 && (_summary?.appStats ?? []).isNotEmpty) ...[
                    _buildSectionHeader('Usage by Application', 'Breakdown of screen time across monitored apps.'),
                    const SizedBox(height: Spacing.sm),
                    EzzeCard(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 52,
                                    sections: _buildPieSections(),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatSeconds(_summary?.totalUsageSeconds ?? 0),
                                      style: AppTypography.monoSmall.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'total',
                                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Spacing.lg),
                          // Legend
                          Wrap(
                            spacing: Spacing.md,
                            runSpacing: Spacing.sm,
                            children: (_summary?.appStats.take(6) ?? []).map((app) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _getChartColor(app.packageName),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.xs),
                                  Text(
                                    app.appName,
                                    style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],

                  // Per-App Usage Details List
                  _buildSectionHeader('App Breakdown', 'Individual application details and limits.'),
                  const SizedBox(height: Spacing.sm),
                  if ((_summary?.appStats ?? []).isEmpty)
                    EzzeCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Text(
                            'No monitored app usage recorded in this period.',
                            style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_summary!.appStats.map((app) {
                      final isOver = app.budgetRatio >= 1.0 && app.usageSeconds > 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: EzzeCard(
                          child: Row(
                            children: [
                              AppIconView(
                                base64Icon: app.iconBase64,
                                fallbackLetter: app.appName,
                                size: 44,
                              ),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.appName,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${Formatters.formatSeconds(app.usageSeconds)} of ${app.budgetMinutes}m',
                                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                    ),
                                    const SizedBox(height: Spacing.xs),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Radii.xs),
                                      child: LinearProgressIndicator(
                                        value: app.budgetRatio.clamp(0.0, 1.0),
                                        backgroundColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOver ? AppColors.error : AppColors.brandRed,
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Spacing.md),
                              StatusBadge(
                                label: isOver ? 'Exceeded' : '${(app.budgetRatio * 100).round()}%',
                                type: isOver ? BadgeType.error : BadgeType.neutral,
                              ),
                            ],
                          ),
                        ),
                      );
                    })),
                  const SizedBox(height: Spacing.xxl),

                  // Physical Exercise Summary
                  _buildSectionHeader('Physical Exercise Activity', 'Movement recorded during break sessions.'),
                  const SizedBox(height: Spacing.sm),
                  if ((_summary?.exerciseStats ?? []).isEmpty)
                    EzzeCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Text(
                            'No physical exercises logged in this period.',
                            style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                          ),
                        ),
                      ),
                    )
                  else
                    EzzeCard(
                      child: Column(
                        children: _summary!.exerciseStats.map((ex) {
                          final activity = ex.type == 'repetitions'
                              ? '${ex.totalRepetitions} reps'
                              : Formatters.formatSeconds(ex.totalDurationSeconds);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.exerciseName,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${ex.sessionCount} sessions',
                                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                    ),
                                  ],
                                ),
                                Text(
                                  activity,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.brandRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: Spacing.xxl),

                  EzzeButton(
                    text: 'Export Full PDF Report',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.xxxl),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall.copyWith(color: secondaryText)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.bodySmall.copyWith(color: secondaryText)),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    if (_summary == null || _summary!.totalUsageSeconds <= 0) return [];
    final total = _summary!.totalUsageSeconds;

    return _summary!.appStats.map((app) {
      final pct = (app.usageSeconds / total) * 100;
      final color = _getChartColor(app.packageName);

      return PieChartSectionData(
        color: color,
        value: app.usageSeconds.toDouble(),
        title: pct > 8 ? '${pct.round()}%' : '',
        radius: 36,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _getChartColor(String pkg) {
    const colors = [
      AppColors.brandRed,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentAmber,
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
    ];
    final hash = pkg.hashCode.abs();
    return colors[hash % colors.length];
  }

  double _getMaxDailyTrend() {
    if (_summary == null || _summary!.dailyTrends.isEmpty) return 60.0;
    double maxMins = 0;
    for (final t in _summary!.dailyTrends) {
      final mins = t.usageSeconds / 60.0;
      if (mins > maxMins) maxMins = mins;
    }
    return (maxMins * 1.2).clamp(30.0, 1440.0);
  }
}
