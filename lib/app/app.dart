import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../core/platform/native_app_service.dart';
import '../core/utils/date_utils.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/app_management/presentation/app_list_screen.dart';
import '../features/app_management/presentation/app_selector_sheet.dart';
import '../features/breaks/presentation/break_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/monitoring/providers/monitoring_providers.dart';
import '../features/overrides/presentation/override_dialog.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/providers/theme_provider.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/widgets/ezze_bottom_nav_bar.dart';

class EzzeBreakApp extends ConsumerWidget {
  const EzzeBreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Ezze Break',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}

class MainNavigationLayout extends ConsumerStatefulWidget {
  final Map<String, String>? initialPendingAction;

  const MainNavigationLayout({super.key, this.initialPendingAction});

  @override
  ConsumerState<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends ConsumerState<MainNavigationLayout> {
  int _currentIndex = 0;
  String? _lastActionKey;
  DateTime? _lastActionTime;
  bool _isOverrideDialogOpen = false;

  final List<Widget> _destinations = const [
    DashboardScreen(),
    AppListScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    NativeAppService.onPendingActionReceived = (action, pkg) {
      if (!mounted) return;
      _handleAction(action, pkg);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialPendingAction != null) {
        final act = widget.initialPendingAction!['action'] ?? '';
        final p = widget.initialPendingAction!['packageName'] ?? '';
        if (act.isNotEmpty && p.isNotEmpty) {
          _handleAction(act, p);
          return;
        }
      }
      final pending = await NativeAppService.getPendingAction();
      if (pending != null && mounted) {
        _handleAction(pending['action'] ?? '', pending['packageName'] ?? '');
      }
    });
  }

  void _handleAction(String action, String pkg) {
    if (action.isEmpty || pkg.isEmpty) return;
    final key = '$action:$pkg';
    final now = DateTime.now();
    if (_lastActionKey == key &&
        _lastActionTime != null &&
        now.difference(_lastActionTime!).inMilliseconds < 1800) {
      return;
    }
    _lastActionKey = key;
    _lastActionTime = now;

    if (action == 'START_BREAK') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BreakScreen(packageName: pkg)),
      );
    } else if (action == 'START_OVERRIDE') {
      _openOverrideDialog(pkg);
    }
  }

  void _openOverrideDialog(String pkg) async {
    if (_isOverrideDialogOpen) return;
    _isOverrideDialogOpen = true;
    try {
      final db = ref.read(databaseProvider);
      final app = await db.getMonitoredApp(pkg);
      final rule = await db.getRule(pkg);
      final usage = await db.getDailyUsage(pkg, EzzeDateUtils.todayKey());
      if (app != null && rule != null && mounted) {
        await showDialog(
          context: context,
          builder: (_) => OverrideDialog(
            app: app,
            usageSeconds: usage?.accumulatedSeconds ?? 0,
            budgetMinutes: rule.dailyBudgetMinutes,
          ),
        );
      }
    } finally {
      _isOverrideDialogOpen = false;
    }
  }

  void _openAddAppSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _destinations,
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandRed.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _openAddAppSheet,
                tooltip: 'Add Applications',
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: EzzeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          NavItemData(
            outlineIcon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          NavItemData(
            outlineIcon: Icons.apps_outlined,
            activeIcon: Icons.apps_rounded,
            label: 'My Apps',
          ),
          NavItemData(
            outlineIcon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Insights',
          ),
          NavItemData(
            outlineIcon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
