import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_motion.dart';

class PinInputField extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool isSuccess;
  final bool autoFocus;

  const PinInputField({
    super.key,
    this.length = 8,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.isSuccess = false,
    this.autoFocus = true,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _shakeController = AnimationController(
      vsync: this,
      duration: EzzeMotion.pinErrorShake,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(PinInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextChange(String text) {
    HapticFeedback.selectionClick();
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentText = widget.controller.text;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Shake oscillation: sin(t * pi * 4) * 10
        final offset = widget.hasError
            ? math.sin(_shakeAnimation.value * math.pi * 4) * 10.0
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden real TextField for system soft keyboard
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onTextChange,
                  autofocus: widget.autoFocus,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            // Custom Visual Cells
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                // 8 cells + 6 gaps (4px) + 1 center gap (12px)
                // total gaps = 6 * 4 + 12 = 36px
                final cellWidth = ((totalWidth - 44) / widget.length).clamp(32.0, 44.0);
                final cellHeight = cellWidth * 1.35;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.length, (index) {
                    final isFilled = index < currentText.length;
                    final isActive = index == currentText.length && _focusNode.hasFocus;
                    final digit = isFilled ? currentText[index] : '';

                    Color borderColor;
                    if (widget.hasError) {
                      borderColor = AppColors.error;
                    } else if (widget.isSuccess) {
                      borderColor = AppColors.success;
                    } else if (isActive) {
                      borderColor = AppColors.brandRed;
                    } else if (isFilled) {
                      borderColor = isDark ? AppColors.darkBorderFocused : AppColors.brandRed;
                    } else {
                      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                    }

                    final isCenterGap = index == (widget.length / 2) - 1;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.length - 1
                            ? 0
                            : (isCenterGap ? 12.0 : 4.0),
                      ),
                      child: AnimatedContainer(
                        duration: EzzeMotion.pinDigitEntry,
                        curve: EzzeMotion.bounce,
                        width: cellWidth,
                        height: cellHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: Border.all(
                            color: borderColor,
                            width: isActive ? 2.0 : 1.2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.brandRed.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: AppTypography.mono.copyWith(
                            fontSize: 22,
                            color: widget.hasError
                                ? AppColors.error
                                : (widget.isSuccess
                                    ? AppColors.success
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary)),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
