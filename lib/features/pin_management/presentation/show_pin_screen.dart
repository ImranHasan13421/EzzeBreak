import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class ShowPinScreen extends ConsumerStatefulWidget {
  const ShowPinScreen({super.key});

  @override
  ConsumerState<ShowPinScreen> createState() => _ShowPinScreenState();
}

class _ShowPinScreenState extends ConsumerState<ShowPinScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _copyToClipboard(String pin) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: pin));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinAsync = ref.watch(pinStateNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Daily PIN', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: pinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandRed)),
        error: (err, _) => Center(child: Text('Error loading PIN: $err')),
        data: (pinState) {
          final remaining = pinState.remainingValidity();
          final remainingSeconds = remaining.inSeconds;
          final remainingFormatted = Formatters.formatSeconds(remainingSeconds);

          final pin = pinState.currentPin;
          final part1 = pin.length >= 4 ? pin.substring(0, 4) : pin;
          final part2 = pin.length > 4 ? pin.substring(4) : '';
          final spacedPin = '$part1  $part2';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
            children: [
              // Hero PIN Display Card
              EzzeCard(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  children: [
                    Text(
                      'Today\'s 8-Digit PIN',
                      style: AppTypography.titleSmall.copyWith(
                        color: secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      spacedPin,
                      style: AppTypography.mono.copyWith(
                        fontSize: 34,
                        letterSpacing: 6,
                        color: AppColors.brandRed,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppColors.brandRed),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'Valid until midnight ($remainingFormatted remaining)',
                          style: AppTypography.bodySmall.copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    EzzeButton(
                      text: 'Copy PIN to Clipboard',
                      variant: EzzeButtonVariant.outline,
                      icon: Icons.copy_rounded,
                      onPressed: () => _copyToClipboard(pin),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xxl),

              // How It Works Info Card
              Text(
                'How the PIN Works',
                style: AppTypography.titleLarge.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              EzzeCard(
                child: Column(
                  children: [
                    _buildFeatureBullet(
                      Icons.lock_clock_rounded,
                      'Deterministic Rotation',
                      'Generated mathematically from date + device ID. Changes automatically at midnight.',
                    ),
                    const Divider(),
                    _buildFeatureBullet(
                      Icons.wifi_off_rounded,
                      '100% Offline Privacy',
                      'No internet required. Zero communication with external servers or cloud.',
                    ),
                    const Divider(),
                    _buildFeatureBullet(
                      Icons.psychology_rounded,
                      'Mindful Friction',
                      'Provides intentional friction to break addictive muscle-memory loops.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Pro Tip Card
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, size: 24, color: AppColors.accentAmber),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wellbeing Tip',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Write your daily PIN on a sticky note and place it in another room. The physical distance creates mindful pause before resuming apps.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandRed),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(color: primaryText, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.bodySmall.copyWith(color: secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
