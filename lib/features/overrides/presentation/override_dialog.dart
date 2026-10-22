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
import '../../monitoring/providers/monitoring_providers.dart';
import '../../pin_management/presentation/pin_entry_screen.dart';

class OverrideDialog extends ConsumerStatefulWidget {
  final MonitoredApp app;
  final int usageSeconds;
  final int budgetMinutes;

  const OverrideDialog({
    super.key,
    required this.app,
    required this.usageSeconds,
    required this.budgetMinutes,
  });

  @override
  ConsumerState<OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends ConsumerState<OverrideDialog> {
  int _selectedExtensionMinutes = 15;
  final List<int> _extensionOptions = [15, 30, 45, 60];

  void _proceedToPin() async {
    final monitor = ref.read(usageMonitorServiceProvider);

    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinEntryScreen(
          title: 'Confirm Extension',
          subtitle:
              'Enter today\'s 8-digit PIN to authorize a $_selectedExtensionMinutes-minute extension for ${widget.app.appName}.',
          onValidated: (pin) async {
            await monitor.authorizeOverride(
              packageName: widget.app.packageName,
              extensionMinutes: _selectedExtensionMinutes,
              pin: pin,
            );
          },
        ),
      ),
    );

    if (unlocked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authorized ${_selectedExtensionMinutes}m extension for ${widget.app.appName}.'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final usedMinutes = widget.usageSeconds ~/ 60;
    final overMinutes = (usedMinutes - widget.budgetMinutes).clamp(0, 9999);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconView(
                base64Icon: widget.app.iconBase64,
                fallbackLetter: widget.app.appName,
                size: 54,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '🔓 Override ${widget.app.appName}',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'You have exhausted your daily allowance.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: secondaryText),
              ),
              const SizedBox(height: Spacing.md),

              // Usage Breakdown Card
              EzzeCard(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Usage', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                        Text(Formatters.formatMinutes(usedMinutes), style: AppTypography.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Budget', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                        Text(Formatters.formatMinutes(widget.budgetMinutes), style: AppTypography.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Over Budget By', style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                        Text(
                          '${overMinutes}m',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Extension Duration Selector
              EzzeCard(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Override Duration',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: _extensionOptions.map((mins) {
                        final isSel = _selectedExtensionMinutes == mins;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () => setState(() => _selectedExtensionMinutes = mins),
                              borderRadius: BorderRadius.circular(Radii.md),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.brandRed.withValues(alpha: 0.18)
                                      : (isDark ? AppColors.darkBg3 : AppColors.lightBg3),
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  border: Border.all(
                                    color: isSel ? AppColors.brandRed : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$mins m',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isSel ? AppColors.brandRed : primaryText,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Spacing.md),

            // Warning note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.accentAmber),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      'Overriding requires today\'s 8-digit PIN.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // Actions
            EzzeButton(
              text: 'Enter PIN →',
              icon: Icons.lock_open_rounded,
              onPressed: _proceedToPin,
            ),
            const SizedBox(height: Spacing.sm),
            EzzeButton(
              text: 'Cancel',
              variant: EzzeButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ),
  );
}
}
