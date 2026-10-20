import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../settings/providers/theme_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(profileNameProvider.notifier).setName(name);
    }
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Indicators & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.brandRed
                              : (isDark ? AppColors.darkBg3 : AppColors.lightBg3),
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: _complete,
                      child: Text(
                        'Skip',
                        style: AppTypography.titleSmall.copyWith(color: secondaryText),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Content Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(primaryText, secondaryText, isDark),
                  _buildHowItWorksPage(primaryText, secondaryText, isDark),
                  _buildProfilePage(primaryText, secondaryText, isDark),
                  _buildPermissionsPage(primaryText, secondaryText, isDark),
                  _buildReadyPage(primaryText, secondaryText, isDark),
                ],
              ),
            ),

            // Bottom CTA Button
            Padding(
              padding: const EdgeInsets.all(Spacing.xxl),
              child: EzzeButton(
                text: _currentPage == 0
                    ? 'Get Started'
                    : _currentPage == 4
                        ? 'Enter Ezze Break'
                        : 'Continue',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(Color primaryText, Color secondaryText, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.xxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandRed.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.xxl),
              child: Image.asset(
                'assets/logo/applogo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'EZZE BREAK',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.brandRed,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Use mindfully.\nMove regularly.\nFeel better.',
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'A 100% private, offline-first digital wellbeing companion designed to help you balance screen time with intentional movement.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: secondaryText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage(Color primaryText, Color secondaryText, bool isDark) {
    final items = [
      {
        'icon': Icons.timer_outlined,
        'title': 'Usage & Session Limits',
        'desc': 'Set daily screen budgets and continuous session limits per application.',
      },
      {
        'icon': Icons.fitness_center_rounded,
        'title': 'Active Physical Breaks',
        'desc': 'Take refreshing movement breaks with push-ups, squats, or stretching.',
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'Daily 8-Digit PIN',
        'desc': 'A secure rolling 24-hour PIN provides mindful friction before resuming.',
      },
      {
        'icon': Icons.shield_outlined,
        'title': '100% Offline & Private',
        'desc': 'Zero accounts, zero trackers, zero cloud sync. All your data stays on your phone.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          Text(
            'How Ezze Break Works',
            style: AppTypography.headlineMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Designed for genuine self-control without invasive cloud tracking.',
            style: AppTypography.bodySmall.copyWith(color: secondaryText),
          ),
          const SizedBox(height: Spacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return EzzeCard(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColors.brandRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTypography.titleMedium.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: AppTypography.bodySmall.copyWith(color: secondaryText, height: 1.3),
                            ),
                          ],
                        ),
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

  Widget _buildProfilePage(Color primaryText, Color secondaryText, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          Text(
            'Your Profile',
            style: AppTypography.headlineMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'How should we greet you? Stored completely offline on your device.',
            style: AppTypography.bodySmall.copyWith(color: secondaryText),
          ),
          const SizedBox(height: Spacing.xxl),
          TextField(
            controller: _nameController,
            style: AppTypography.bodyLarge.copyWith(color: primaryText),
            decoration: const InputDecoration(
              labelText: 'Display Name (Optional)',
              hintText: 'e.g. Alex, Sam, Mindful Mover',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.brandRed, size: 22),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    'No email, password, or internet connection required. Your identity is stored only in local SQLite.',
                    style: AppTypography.bodySmall.copyWith(color: secondaryText, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(Color primaryText, Color secondaryText, bool isDark) {
    final perms = ref.watch(permissionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          Text(
            'Configure Monitoring',
            style: AppTypography.headlineMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Android requires explicit permissions to track app foreground time and present break restrictions.',
            style: AppTypography.bodySmall.copyWith(color: secondaryText),
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ListView(
              children: [
                _buildPermissionTile(
                  title: '1. Usage Access',
                  desc: 'Allows calculating daily foreground usage time for monitored applications.',
                  isGranted: perms.hasUsageAccess,
                  onGrant: () async {
                    await NativeAppService.openUsageSettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const SizedBox(height: Spacing.md),
                _buildPermissionTile(
                  title: '2. Display Over Other Apps',
                  desc: 'Allows presenting the restriction overlay when session limit is reached.',
                  isGranted: perms.hasOverlay,
                  onGrant: () async {
                    await NativeAppService.openOverlaySettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const SizedBox(height: Spacing.md),
                _buildPermissionTile(
                  title: '3. Accessibility Service',
                  desc: 'Detects foreground app switches to enforce limits without polling battery drain.',
                  isGranted: perms.hasAccessibility,
                  onGrant: () async {
                    await NativeAppService.openAccessibilitySettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
                const SizedBox(height: Spacing.md),
                _buildPermissionTile(
                  title: '4. Notifications',
                  desc: 'Sends gentle break reminders and exercise countdown notifications.',
                  isGranted: perms.hasNotification,
                  onGrant: () async {
                    await NativeAppService.openNotificationSettings();
                    ref.read(permissionsProvider.notifier).checkAll();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return EzzeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(color: primaryText, fontWeight: FontWeight.bold),
              ),
              StatusBadge(
                label: isGranted ? 'Active' : 'Required',
                type: isGranted ? BadgeType.active : BadgeType.warning,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: AppTypography.bodySmall.copyWith(color: secondaryText, height: 1.3)),
          if (!isGranted) ...[
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 38,
              child: OutlinedButton(
                onPressed: onGrant,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandRed,
                  side: const BorderSide(color: AppColors.brandRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
                ),
                child: const Text('Open Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyPage(Color primaryText, Color secondaryText, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.xl),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 56),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            "You're Ready to Go!",
            style: AppTypography.headlineMedium.copyWith(color: primaryText, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Add your most distracting apps, set your daily budget and session break timers, and build mindful screen habits.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: secondaryText, height: 1.5),
          ),
          const SizedBox(height: Spacing.xl),
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                _buildSummaryRow(Icons.pin_outlined, '8-Digit Rolling PIN', 'Generated mathematically each day for mindful friction.'),
                const Divider(),
                _buildSummaryRow(Icons.offline_pin_outlined, 'Offline Guarantee', 'All data is stored exclusively in your local database.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandRed, size: 22),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              Text(desc, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
