import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_motion.dart';

enum EzzeButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

class EzzeButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final EzzeButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;

  const EzzeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = EzzeButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.borderRadius = Radii.md,
  });

  const EzzeButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.borderRadius = Radii.md,
  }) : variant = EzzeButtonVariant.danger;

  @override
  State<EzzeButton> createState() => _EzzeButtonState();
}

class _EzzeButtonState extends State<EzzeButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color fg;
    BoxDecoration decoration;

    switch (widget.variant) {
      case EzzeButtonVariant.primary:
        fg = AppColors.white;
        decoration = BoxDecoration(
          gradient: isEnabled ? AppColors.brandGradient : null,
          color: isEnabled ? null : (isDark ? AppColors.darkBg3 : AppColors.lightBg3),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.brandRed.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
        break;

      case EzzeButtonVariant.secondary:
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        decoration = BoxDecoration(
          color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        );
        break;

      case EzzeButtonVariant.outline:
        fg = AppColors.brandRed;
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: AppColors.brandRed,
            width: 1.5,
          ),
        );
        break;

      case EzzeButtonVariant.ghost:
        fg = AppColors.brandRed;
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        );
        break;

      case EzzeButtonVariant.danger:
        fg = AppColors.white;
        decoration = BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
        break;
    }

    final childContent = widget.isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: Spacing.sm),
              ],
              Text(
                widget.text,
                style: AppTypography.titleMedium.copyWith(
                  color: isEnabled ? fg : (isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled),
                ),
              ),
            ],
          );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: EzzeMotion.buttonPress,
      curve: EzzeMotion.standard,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: GestureDetector(
          onTapDown: isEnabled ? _handleTapDown : null,
          onTapUp: isEnabled ? _handleTapUp : null,
          onTapCancel: isEnabled ? _handleTapCancel : null,
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed?.call();
                }
              : null,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            decoration: decoration,
            child: childContent,
          ),
        ),
      ),
    );
  }
}
