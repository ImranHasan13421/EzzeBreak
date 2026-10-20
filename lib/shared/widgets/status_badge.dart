import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum BadgeType {
  active,
  warning,
  error,
  neutral,
  info,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color dotColor;

    switch (type) {
      case BadgeType.active:
        bg = AppColors.successBg;
        fg = AppColors.success;
        dotColor = AppColors.success;
        break;
      case BadgeType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        dotColor = AppColors.warning;
        break;
      case BadgeType.error:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        dotColor = AppColors.error;
        break;
      case BadgeType.neutral:
        bg = isDark ? AppColors.darkBg3 : AppColors.lightBg3;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        dotColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
        break;
      case BadgeType.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        dotColor = AppColors.info;
        break;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: Spacing.xs),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
