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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear History?',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will delete all past usage sessions, daily usage records, break logs, and exercise activity. Monitored app rules and exercise presets will be preserved.',
          style: AppTypography.bodyMedium,
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

  void _showResetAllDialog(BuildContext context, WidgetRef ref) {
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
          style: AppTypography.bodyMedium,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        content: Text(message, style: AppTypography.bodyMedium.copyWith(height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got It')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final themeMode = ref.watch(themeModeProvider);
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
        children: [
          // Theme Segmented Control
          _buildSectionHeader('Appearance & Theme', 'Customize color mode for day and night use.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                _buildThemeOption(
                  context,
                  ref,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  mode: ThemeMode.system,
                  currentMode: themeMode,
                ),
                const SizedBox(width: Spacing.sm),
                _buildThemeOption(
                  context,
                  ref,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  mode: ThemeMode.light,
                  currentMode: themeMode,
                ),
                const SizedBox(width: Spacing.sm),
                _buildThemeOption(
                  context,
                  ref,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  currentMode: themeMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),

          // Android Permissions Section
          _buildSectionHeader('System Permissions', 'Permissions required for monitoring and restriction enforcement.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            child: Column(
              children: [
                _buildPermissionRow(
                  context,
                  title: 'Usage Access',
                  desc: 'Calculates foreground app screen time.',
                  isGranted: perms.hasUsageAccess,
                  onOpen: () async {
                    await NativeAppService.openUsageSettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const Divider(),
                _buildPermissionRow(
                  context,
                  title: 'Display Over Other Apps',
                  desc: 'Presents restriction overlay when limit reached.',
                  isGranted: perms.hasOverlay,
                  onOpen: () async {
                    await NativeAppService.openOverlaySettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const Divider(),
                _buildPermissionRow(
                  context,
                  title: 'Accessibility Service',
                  desc: 'Detects active foreground app switches.',
                  isGranted: perms.hasAccessibility,
                  onOpen: () async {
                    await NativeAppService.openAccessibilitySettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const Divider(),
                _buildPermissionRow(
                  context,
                  title: 'Notifications',
                  desc: 'Delivers break alerts and rest countdowns.',
                  isGranted: perms.hasNotification,
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
          _buildSectionHeader('Architecture & Policies', 'Understand how Ezze Break manages privacy and time.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nightlight_round, color: AppColors.brandRed),
                  title: Text('Daily Usage Reset Policy', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
                  title: Text('24-Hour PIN Rotation', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
                  title: Text('100% Offline Guarantee', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
          _buildSectionHeader('Data Management', 'Manage database records and historical analytics.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.accentAmber),
                  title: Text('Clear History', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Deletes past logs; keeps app rules', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showClearHistoryDialog(context, ref),
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
                  subtitle: Text('Factory reset app and local database', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showResetAllDialog(context, ref),
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
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: secondaryText),
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
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildPermissionRow(
    BuildContext context, {
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onOpen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: primaryText)),
                  const SizedBox(width: Spacing.sm),
                  StatusBadge(
                    label: isGranted ? 'Active' : 'Required',
                    type: isGranted ? BadgeType.active : BadgeType.warning,
                    showDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall.copyWith(color: secondaryText)),
            ],
          ),
        ),
        if (!isGranted)
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandRed,
                side: const BorderSide(color: AppColors.brandRed),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
              ),
              child: const Text('Grant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
