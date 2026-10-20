import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../shared/models/app_rule.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class AppSelectorSheet extends ConsumerStatefulWidget {
  const AppSelectorSheet({super.key});

  @override
  ConsumerState<AppSelectorSheet> createState() => _AppSelectorSheetState();
}

class _AppSelectorSheetState extends ConsumerState<AppSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  final Set<String> _selectedPackages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInstalledApps() async {
    final apps = await NativeAppService.getInstalledApps();
    final monitored = ref.read(monitoredAppsListProvider);
    final monitoredPkgs = monitored.map((a) => a.packageName).toSet();

    // Filter out already monitored apps
    final unmonitored = apps.where((a) {
      final pkg = a['packageName'] as String;
      return pkg != AppConstants.appPackage && !monitoredPkgs.contains(pkg);
    }).toList();

    if (mounted) {
      setState(() {
        _allApps = unmonitored;
        _filteredApps = unmonitored;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = _allApps;
      } else {
        _filteredApps = _allApps.where((app) {
          final name = (app['appName'] as String? ?? '').toLowerCase();
          final pkg = (app['packageName'] as String? ?? '').toLowerCase();
          return name.contains(query) || pkg.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSelect(String pkg) {
    setState(() {
      if (_selectedPackages.contains(pkg)) {
        _selectedPackages.remove(pkg);
      } else {
        _selectedPackages.add(pkg);
      }
    });
  }

  void _addSelectedApps() async {
    final monitoredNotifier = ref.read(monitoredAppsListProvider.notifier);

    for (final pkg in _selectedPackages) {
      final appData = _allApps.firstWhere((a) => a['packageName'] == pkg);
      final monitoredApp = MonitoredApp(
        packageName: pkg,
        appName: appData['appName'] as String,
        iconBase64: appData['iconBase64'] as String?,
        isSystemApp: appData['isSystemApp'] as bool? ?? false,
        isMonitored: true,
      );

      final rule = AppRule(
        packageName: pkg,
        dailyBudgetMinutes: AppConstants.defaultDailyBudgetMinutes,
        sessionLimitMinutes: AppConstants.defaultSessionLimitMinutes,
        breakDurationMinutes: AppConstants.defaultBreakDurationMinutes,
      );

      await monitoredNotifier.addApp(monitoredApp, rule);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkGlassStroke : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: Spacing.md),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(Radii.full),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Applications',
                      style: AppTypography.headlineSmall.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select apps to monitor habits and breaks',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium.copyWith(color: primaryText),
              decoration: InputDecoration(
                hintText: 'Search installed applications...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: Spacing.lg),
                        Text('Scanning installed applications...'),
                      ],
                    ),
                  )
                : _filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apps_rounded, size: 48, color: secondaryText),
                            const SizedBox(height: Spacing.md),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No eligible applications found'
                                  : 'No applications match "${_searchController.text}"',
                              style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final pkg = app['packageName'] as String;
                          final name = app['appName'] as String;
                          final iconBase64 = app['iconBase64'] as String?;
                          final isSystem = app['isSystemApp'] as bool? ?? false;
                          final isSelected = _selectedPackages.contains(pkg);

                          return ListTile(
                            onTap: () => _toggleSelect(pkg),
                            leading: AppIconView(
                              base64Icon: iconBase64,
                              fallbackLetter: name,
                              size: 44,
                            ),
                            title: Text(
                              name,
                              style: AppTypography.titleMedium.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pkg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                  ),
                                ),
                                if (isSystem) ...[
                                  const SizedBox(width: Spacing.xs),
                                  const StatusBadge(label: 'System', type: BadgeType.neutral),
                                ],
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: AppColors.brandRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.xs),
                              ),
                              onChanged: (_) => _toggleSelect(pkg),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action
          if (_selectedPackages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: EzzeButton(
                text: 'Done (${_selectedPackages.length} selected)',
                onPressed: _addSelectedApps,
              ),
            ),
        ],
      ),
    );
  }
}
