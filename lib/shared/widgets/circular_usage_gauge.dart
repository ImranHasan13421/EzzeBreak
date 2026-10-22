import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_motion.dart';
import '../../core/utils/formatters.dart';

class CircularUsageGauge extends StatefulWidget {
  final int usedMinutes;
  final int budgetMinutes;
  final double size;
  final double strokeWidth;
  final VoidCallback? onTap;

  const CircularUsageGauge({
    super.key,
    required this.usedMinutes,
    required this.budgetMinutes,
    this.size = 180,
    this.strokeWidth = 10,
    this.onTap,
  });

  @override
  State<CircularUsageGauge> createState() => _CircularUsageGaugeState();
}

class _CircularUsageGaugeState extends State<CircularUsageGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: EzzeMotion.gaugeArc,
    );
    _setupAnimation();
  }

  @override
  void didUpdateWidget(CircularUsageGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usedMinutes != widget.usedMinutes ||
        oldWidget.budgetMinutes != widget.budgetMinutes) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    final targetRatio = widget.budgetMinutes > 0
        ? (widget.usedMinutes / widget.budgetMinutes).clamp(0.0, 1.0)
        : 0.0;
    _progressAnimation = Tween<double>(begin: 0.0, end: targetRatio).animate(
      CurvedAnimation(parent: _controller, curve: EzzeMotion.standard),
    );
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverBudget =
        widget.budgetMinutes > 0 && widget.usedMinutes >= widget.budgetMinutes;

    final usedTimeStr = Formatters.formatCompact(widget.usedMinutes);
    final budgetTimeStr = widget.budgetMinutes > 0
        ? Formatters.formatCompact(widget.budgetMinutes)
        : '0m';

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _GaugePainter(
                      progress: _progressAnimation.value,
                      strokeWidth: widget.strokeWidth,
                      isOverBudget: isOverBudget,
                      trackColor: isDark
                          ? AppColors.darkBg3.withValues(alpha: 0.6)
                          : AppColors.lightBg3,
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(widget.strokeWidth + 14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            usedTimeStr,
                            style: TextStyle(
                              fontFamily: AppTypography.primaryFont,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isOverBudget
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'of $budgetTimeStr',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _GaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final bool isOverBudget;
  final Color trackColor;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.isOverBudget,
    required this.trackColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    // Progress Arc Paint
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint progressPaint;
    if (isOverBudget) {
      progressPaint = Paint()
        ..color = AppColors.error
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
    } else {
      progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: const [
            Color(0xFFE63946),
            Color(0xFFFF6B6B),
            Color(0xFFE63946),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
    }

    // Starting from 12 o'clock (-pi / 2)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOverBudget != isOverBudget ||
        oldDelegate.trackColor != trackColor;
  }
}
