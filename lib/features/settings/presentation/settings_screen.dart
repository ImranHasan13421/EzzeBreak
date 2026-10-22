import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh permission statuses on opening settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsProvider.notifier).checkAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning from system settings
      ref.read(permissionsProvider.notifier).checkAll();
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear History?',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        content: Text(
          'This will delete all past usage sessions, daily usage records, break logs, and exercise activity. Monitored app rules and exercise presets will be preserved.',
          style: AppTypography.bodyMedium.copyWith(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final db = ref.read(databaseProvider);
              await db.clearHistory();
              ref.read(todayUsageProvider.notifier).refresh();
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('History cleared successfully.')),
              );
            },
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  void _showResetAllDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset All Application Data?',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'WARNING: This will permanently erase ALL data, monitored apps, rules, history, and reset onboarding. This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              final db = ref.read(databaseProvider);
              await db.clearAllData();
              await ref.read(onboardingCompletedProvider.notifier).resetOnboarding();
              nav.pop();
              rootNav.popUntil((route) => route.isFirst);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: secondaryText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
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
    final scaffoldBg = isDark ? AppColors.darkBg0 : AppColors.lightBg0;

    final themeMode = ref.watch(themeModeProvider);
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        title: Text(
          'Settings',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
          children: [
            // Theme Segmented Control
            _buildSectionHeader(
              'Appearance & Theme',
              'Customize color mode for day and night use.',
              primaryText,
              secondaryText,
            ),
            const SizedBox(height: Spacing.sm),
            EzzeCard(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  _buildThemeOption(
                    label: 'System',
                    icon: Icons.brightness_auto_rounded,
                    mode: ThemeMode.system,
                    currentMode: themeMode,
                    isDark: isDark,
                  ),
                  const SizedBox(width: Spacing.sm),
                  _buildThemeOption(
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    mode: ThemeMode.light,
                    currentMode: themeMode,
                    isDark: isDark,
                  ),
                  const SizedBox(width: Spacing.sm),
                  _buildThemeOption(
                    label: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    mode: ThemeMode.dark,
                    currentMode: themeMode,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxl),

            // Android Permissions Section
            _buildSectionHeader(
              'System Permissions',
              'Permissions required for monitoring and restriction enforcement.',
              primaryText,
              secondaryText,
            ),
            const SizedBox(height: Spacing.sm),
            EzzeCard(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                children: [
                  _buildPermissionRow(
                    icon: Icons.query_stats_rounded,
                    title: 'Usage Access',
                    desc: 'Calculates daily foreground usage time for monitored applications.',
                    isGranted: perms.hasUsageAccess,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onOpen: () async {
                      await NativeAppService.openUsageSettings();
                      ref.read(permissionsProvider.notifier).checkAll();
                    },
                  ),
                  const Divider(height: Spacing.xl),
                  _buildPermissionRow(
                    icon: Icons.layers_outlined,
                    title: 'Display Over Other Apps',
                    desc: 'Presents the mindful break restriction overlay when limits are reached.',
                    isGranted: perms.hasOverlay,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onOpen: () async {
                      await NativeAppService.openOverlaySettings();
                      ref.read(permissionsProvider.notifier).checkAll();
                    },
                  ),
                  const Divider(height: Spacing.xl),
                  _buildPermissionRow(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Accessibility Service',
                    desc: 'Detects active foreground app switches to enforce limits without battery drain.',
                    isGranted: perms.hasAccessibility,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onOpen: () async {
                      await NativeAppService.openAccessibilitySettings();
                      ref.read(permissionsProvider.notifier).checkAll();
                    },
                  ),
                  const Divider(height: Spacing.xl),
                  _buildPermissionRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    desc: 'Delivers break reminders and physical exercise rest alerts.',
                    isGranted: perms.hasNotification,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onOpen: () async {
                      await NativeAppService.openNotificationSettings();
                      ref.read(permissionsProvider.notifier).checkAll();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxl),

            // Architecture & Logic Info
            _buildSectionHeader(
              'Architecture & Policies',
              'Understand how Ezze Break manages privacy and time.',
              primaryText,
              secondaryText,
            ),
            const SizedBox(height: Spacing.sm),
            EzzeCard(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.nightlight_round, color: AppColors.brandRed),
                    title: Text(
                      'Daily Usage Reset Policy',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    subtitle: Text(
                      'Resets at 12:00 AM local midnight',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: secondaryText),
                    onTap: () => _showInfoDialog(
                      context,
                      'Daily Usage Reset',
                      'Daily screen time budgets reset at local midnight (00:00). When a new calendar day begins, daily usage counters reset to 0 while preserving historical records for weekly analytics.',
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pin_outlined, color: AppColors.brandRed),
                    title: Text(
                      '24-Hour PIN Rotation',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    subtitle: Text(
                      'Deterministic rolling 8-digit security key',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: secondaryText),
                    onTap: () => _showInfoDialog(
                      context,
                      '24-Hour PIN Rotation',
                      'The cryptographically deterministic 8-digit PIN rotates on a rolling 24-hour validity window. It is stored exclusively on your device to create mindful pause points before unlocks and extensions.',
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined, color: AppColors.brandRed),
                    title: Text(
                      '100% Offline Guarantee',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    subtitle: Text(
                      'Zero internet permissions, zero telemetry',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: secondaryText),
                    onTap: () => _showInfoDialog(
                      context,
                      'Offline Architecture',
                      'Ezze Break has zero network permissions, zero cloud database connections, zero analytics SDKs, and zero telemetry. Everything runs locally in SQLite on your phone.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxl),

            // Data Management
            _buildSectionHeader(
              'Data Management',
              'Manage database records and historical analytics.',
              primaryText,
              secondaryText,
            ),
            const SizedBox(height: Spacing.sm),
            EzzeCard(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.accentAmber),
                    title: Text(
                      'Clear History',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    subtitle: Text(
                      'Deletes past logs; keeps app rules',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: secondaryText),
                    onTap: () => _showClearHistoryDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore_rounded, color: AppColors.error),
                    title: Text(
                      'Reset All Data',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Factory reset app and local database',
                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: secondaryText),
                    onTap: () => _showResetAllDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxl),

            // About App Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Ezze Break v2.0.0',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '100% Offline & Private Digital Wellbeing',
                    style: AppTypography.bodySmall.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Package: ${AppConstants.appPackage}',
                    style: AppTypography.bodySmall.copyWith(color: secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandRed
                : (isDark ? AppColors.darkBg2 : AppColors.lightBg2),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandRed
                  : (isDark ? AppColors.darkGlassStroke : AppColors.lightBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    Color primaryText,
    Color secondaryText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
      ],
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String desc,
    required bool isGranted,
    required Color primaryText,
    required Color secondaryText,
    required VoidCallback onOpen,
  }) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isGranted ? AppColors.accentGreen : AppColors.brandRed,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              StatusBadge(
                label: isGranted ? 'Active' : 'Required',
                type: isGranted ? BadgeType.active : BadgeType.warning,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              desc,
              style: AppTypography.bodySmall.copyWith(
                color: secondaryText,
                height: 1.3,
              ),
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.settings_outlined, size: 14),
                  label: const Text(
                    'Grant Permission',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandRed,
                    side: const BorderSide(color: AppColors.brandRed),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
