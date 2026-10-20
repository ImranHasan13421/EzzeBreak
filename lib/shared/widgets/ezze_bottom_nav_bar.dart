import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';

class NavItemData {
  final IconData outlineIcon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.outlineIcon,
    required this.activeIcon,
    required this.label,
  });
}

class EzzeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  const EzzeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg1 : AppColors.lightBg1;
    final topBorderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: topBorderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / items.length;

              return Stack(
                children: [
                  // Sliding indicator pill at bottom of active tab
                  AnimatedPositioned(
                    duration: EzzeMotion.tabSwitch,
                    curve: EzzeMotion.standard,
                    left: (currentIndex * tabWidth) + (tabWidth - 32) / 2,
                    bottom: 4,
                    width: 32,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.brandRed,
                        borderRadius: BorderRadius.circular(Radii.full),
                      ),
                    ),
                  ),

                  // Tab Items
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == currentIndex;

                      final iconColor = isSelected
                          ? AppColors.brandRed
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary);
                      final textColor = isSelected
                          ? AppColors.brandRed
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary);

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            if (!isSelected) {
                              HapticFeedback.lightImpact();
                              onTap(index);
                            }
                          },
                          splashColor: AppColors.brandRed.withValues(alpha: 0.1),
                          highlightColor: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.08 : 1.0,
                                duration: EzzeMotion.fast,
                                curve: EzzeMotion.standard,
                                child: Icon(
                                  isSelected ? item.activeIcon : item.outlineIcon,
                                  size: 24,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                style: AppTypography.labelMedium.copyWith(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
