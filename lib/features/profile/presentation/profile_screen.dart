import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../exercises/presentation/exercise_library_screen.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../pin_management/presentation/show_pin_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final currentName = ref.read(profileNameProvider);
    final ctrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Display Name', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Your name or nickname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(profileNameProvider.notifier).setName(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final displayName = ref.watch(profileNameProvider);
    final todayUsageMap = ref.watch(todayUsageProvider);
    final monitoredApps = ref.watch(monitoredAppsListProvider);

    int totalSecondsToday = 0;
    for (final u in todayUsageMap.values) {
      totalSecondsToday += u.accumulatedSeconds;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
        children: [
          // Profile Header Card
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandRed.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty ? displayName : 'Mindful User',
                        style: AppTypography.titleLarge.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline Personal Profile',
                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Name',
                  onPressed: () => _showEditNameDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Two Stat Cards Side by Side
          Row(
            children: [
              Expanded(
                child: EzzeCard(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usage Today', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        Formatters.formatSeconds(totalSecondsToday),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: EzzeCard(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monitored Apps', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        '${monitoredApps.where((a) => a.isMonitored).length} active',
                        style: AppTypography.titleLarge.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),

          // Quick Navigation Menu Card
          Text(
            'Quick Actions',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pin_outlined, color: AppColors.brandRed),
                  title: Text('Daily 8-Digit PIN', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('View today\'s rolling PIN and validity', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShowPinScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center_outlined, color: AppColors.brandRed),
                  title: Text('Exercise Library', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Manage push-ups, squats, and routines', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.brandRed),
                  title: Text('Export PDF Reports', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Generate downloadable wellbeing reports', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined, color: AppColors.brandRed),
                  title: Text('System Settings', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Themes, permissions, and database controls', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),

          // 100% Offline & Private Card
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.accentGreen, size: 20),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '100% Offline & Private',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'No internet permissions, no external server communication, no telemetry. All screen time calculations and exercise records remain strictly on your device.',
                  style: AppTypography.bodySmall.copyWith(color: secondaryText, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),

          // App Logo and Version
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Image.asset(
                    'assets/logo/applogo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Ezze Break v2.0.0',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use mindfully. Move regularly. Feel better.',
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
}
