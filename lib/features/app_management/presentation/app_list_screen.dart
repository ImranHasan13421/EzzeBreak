import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app_rules/presentation/rule_config_screen.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import 'app_selector_sheet.dart';

enum AppFilter { all, active, paused }

class AppListScreen extends ConsumerStatefulWidget {
  const AppListScreen({super.key});

  @override
  ConsumerState<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends ConsumerState<AppListScreen> {
  AppFilter _filter = AppFilter.all;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAppSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSelectorSheet(),
    );
  }

  void _confirmRemoveApp(BuildContext context, WidgetRef ref, MonitoredApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stop Monitoring ${app.appName}?'),
        content: const Text(
          'The app will no longer be restricted by session limits or break rules. Historical usage data will be preserved in your analytics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await ref.read(monitoredAppsListProvider.notifier).removeApp(app.packageName);
              nav.pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final apps = ref.watch(monitoredAppsListProvider);
    final rules = ref.watch(appRulesMapProvider);
    final todayUsages = ref.watch(todayUsageProvider);

    // Apply Filter and Search
    final filteredApps = apps.where((app) {
      if (_filter == AppFilter.active && !app.isMonitored) return false;
      if (_filter == AppFilter.paused && app.isMonitored) return false;
      if (_searchQuery.isNotEmpty &&
          !app.appName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.titleMedium.copyWith(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  hintStyle: AppTypography.bodyMedium.copyWith(color: secondaryText),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              )
            : Text('My Apps', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Applications',
            onPressed: () => _openAppSelector(context),
          ),
        ],
      ),
      body: apps.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.apps_rounded, size: 54, color: AppColors.brandRed),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      'No Monitored Apps Yet',
                      style: AppTypography.headlineSmall.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Select the applications where you want to reduce screen time and build healthy movement habits.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                    ),
                    const SizedBox(height: Spacing.xl),
                    EzzeButton(
                      text: 'Add Applications',
                      icon: Icons.add_rounded,
                      onPressed: () => _openAppSelector(context),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Filter Segmented Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.sm),
                  child: Row(
                    children: [
                      _buildFilterChip('All (${apps.length})', AppFilter.all),
                      const SizedBox(width: Spacing.sm),
                      _buildFilterChip(
                        'Active (${apps.where((a) => a.isMonitored).length})',
                        AppFilter.active,
                      ),
                      const SizedBox(width: Spacing.sm),
                      _buildFilterChip(
                        'Paused (${apps.where((a) => !a.isMonitored).length})',
                        AppFilter.paused,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xs),

                // App List
                Expanded(
                  child: filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            'No apps match your filter.',
                            style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xxl,
                            vertical: Spacing.md,
                          ),
                          itemCount: filteredApps.length,
                          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final rule = rules[app.packageName];
                            final daily = todayUsages[app.packageName];

                            final usedSec = daily?.accumulatedSeconds ?? 0;
                            final budgetMins = rule?.dailyBudgetMinutes ?? 60;
                            final sessionMins = rule?.sessionLimitMinutes ?? 20;
                            final isOver = daily?.isOverBudget ?? false;
                            final ratio = (daily?.usageRatio ?? 0.0).clamp(0.0, 1.0);

                            return EzzeCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RuleConfigScreen(app: app, initialRule: rule),
                                  ),
                                );
                              },
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    app.appName,
                                                    style: AppTypography.titleLarge.copyWith(
                                                      color: primaryText,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                StatusBadge(
                                                  label: app.isMonitored ? 'Active' : 'Paused',
                                                  type: app.isMonitored
                                                      ? BadgeType.active
                                                      : BadgeType.neutral,
                                                  showDot: true,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${Formatters.formatSeconds(usedSec)} / ${Formatters.formatMinutes(budgetMins)}',
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
                                            : (ratio > 0.75
                                                ? AppColors.warning
                                                : AppColors.brandRed),
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Session Limit: ${sessionMins}m',
                                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                            tooltip: 'Stop monitoring',
                                            color: AppColors.error,
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _confirmRemoveApp(context, ref, app),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right_rounded, size: 22),
                                            visualDensity: VisualDensity.compact,
                                            color: secondaryText,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => RuleConfigScreen(
                                                    app: app,
                                                    initialRule: rule,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, AppFilter filter) {
    final isSelected = _filter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _filter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandRed
              : (isDark ? AppColors.darkBg2 : AppColors.lightBg2),
          borderRadius: BorderRadius.circular(Radii.full),
          border: Border.all(
            color: isSelected
                ? AppColors.brandRed
                : (isDark ? AppColors.darkGlassStroke : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
