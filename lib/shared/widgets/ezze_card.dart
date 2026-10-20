import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum EzzeCardVariant { standard, elevated, accent, status }

class EzzeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final EzzeCardVariant variant;
  final Color? statusColor;

  const EzzeCard({
    super.key,
    required this.child,
    this.padding = Spacing.cardPadding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderRadius = Radii.md,
  })  : variant = EzzeCardVariant.standard,
        statusColor = null;

  const EzzeCard.elevated({
    super.key,
    required this.child,
    this.padding = Spacing.cardPadding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderRadius = Radii.md,
  })  : variant = EzzeCardVariant.elevated,
        statusColor = null;

  const EzzeCard.accent({
    super.key,
    required this.child,
    this.padding = Spacing.cardPadding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderRadius = Radii.md,
  })  : variant = EzzeCardVariant.accent,
        statusColor = null;

  const EzzeCard.status({
    super.key,
    required this.child,
    required this.statusColor,
    this.padding = Spacing.cardPadding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderRadius = Radii.md,
  }) : variant = EzzeCardVariant.status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    if (color != null) {
      bg = color!;
    } else {
      switch (variant) {
        case EzzeCardVariant.elevated:
          bg = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
          break;
        case EzzeCardVariant.standard:
        case EzzeCardVariant.accent:
        case EzzeCardVariant.status:
          bg = isDark ? AppColors.darkBg1 : AppColors.lightBg1;
          break;
      }
    }

    final defaultBorder = isDark ? AppColors.darkGlassStroke : AppColors.lightBorder;
    final strokeColor = borderColor ?? defaultBorder;

    final shadow = isDark
        ? const [
            BoxShadow(
              color: Color(0x4D000000), // 30% black
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0D000000), // 5% black
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ];

    final cardBorder = Border.all(color: strokeColor, width: 1);

    Color? stripeColor;
    if (variant == EzzeCardVariant.status && statusColor != null) {
      stripeColor = statusColor;
    } else if (variant == EzzeCardVariant.accent) {
      stripeColor = AppColors.brandRed;
    }

    Widget innerBody = Padding(
      padding: padding,
      child: child,
    );

    if (stripeColor != null) {
      innerBody = Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: stripeColor),
          ),
          innerBody,
        ],
      );
    }

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: cardBorder,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: innerBody,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
