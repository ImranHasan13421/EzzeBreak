import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_motion.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(String pin)? onValidated;

  const PinEntryScreen({
    super.key,
    this.title = 'Enter 8-Digit PIN',
    this.subtitle = 'Your daily PIN changes every 24 hours for mindful friction.',
    this.onValidated,
  });

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isChecking = false;
  Timer? _lockoutTicker;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: EzzeMotion.pinErrorShake,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _checkLockout();
  }

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _checkLockout() {
    final pinService = ref.read(pinServiceProvider);
    if (pinService.isLockedOut()) {
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final pinService = ref.read(pinServiceProvider);
      if (!pinService.isLockedOut()) {
        timer.cancel();
        setState(() => _errorMessage = null);
      } else {
        final rem = pinService.getRemainingLockout().inSeconds;
        setState(() {
          _errorMessage = 'Too many attempts. Wait ${rem}s to try again.';
        });
      }
    });
  }

  void _onDigitPress(String digit) {
    if (_isChecking) return;
    HapticFeedback.lightImpact();

    final pinService = ref.read(pinServiceProvider);
    if (pinService.isLockedOut()) {
      _checkLockout();
      return;
    }

    if (_enteredPin.length < 8) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 8) {
        _validate();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onPaste() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.length == 8 && int.tryParse(text) != null) {
      setState(() {
        _enteredPin = text;
        _errorMessage = null;
      });
      _validate();
    }
  }

  void _validate() async {
    setState(() => _isChecking = true);
    final pinService = ref.read(pinServiceProvider);
    final isValid = await pinService.validatePin(_enteredPin);

    if (isValid) {
      HapticFeedback.mediumImpact();
      if (widget.onValidated != null) {
        await widget.onValidated!(_enteredPin);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      if (mounted) {
        setState(() {
          _isChecking = false;
          _enteredPin = '';
          if (pinService.isLockedOut()) {
            _startLockoutTimer();
          } else {
            _errorMessage = 'Incorrect PIN. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PIN Verification',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: Spacing.lg),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: secondaryText),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // 8 Visual Digit Cells (Grouped 4-4 with center gap)
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = _errorMessage != null
                    ? math.sin(_shakeAnimation.value * math.pi * 4) * 8.0
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(8, (index) {
                    final hasDigit = index < _enteredPin.length;
                    final isCurrent = index == _enteredPin.length;
                    final isCenterGap = index == 3;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: 3,
                        right: isCenterGap ? 14 : 3,
                      ),
                      child: Container(
                        width: 36,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.error
                                : (isCurrent
                                    ? AppColors.brandRed
                                    : (hasDigit
                                        ? AppColors.brandRed
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder))),
                            width: isCurrent ? 2 : 1.2,
                          ),
                          boxShadow: isCurrent
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
                          hasDigit ? _enteredPin[index] : '',
                          style: AppTypography.mono.copyWith(
                            fontSize: 24,
                            color: _errorMessage != null
                                ? AppColors.error
                                : primaryText,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Error or Loading Indicator
            const SizedBox(height: Spacing.md),
            Container(
              height: 24,
              alignment: Alignment.center,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandRed,
                          ),
                        )
                      : null,
            ),

            const Spacer(),

            // Custom Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.sm),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: Spacing.md),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: Spacing.md),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: Spacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton(
                        child: const Icon(Icons.paste_rounded, size: 22, color: AppColors.brandRed),
                        onTap: _onPaste,
                      ),
                      _buildKeypadDigit('0'),
                      _buildKeypadButton(
                        child: Icon(Icons.backspace_outlined, size: 22, color: secondaryText),
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeypadDigit).toList(),
    );
  }

  Widget _buildKeypadDigit(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return _buildKeypadButton(
      child: Text(
        digit,
        style: AppTypography.titleLarge.copyWith(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _onDigitPress(digit),
    );
  }

  Widget _buildKeypadButton({required Widget child, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 74,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: isDark ? AppColors.darkGlassStroke : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Center(child: child),
        ),
      ),
    );
  }
}
