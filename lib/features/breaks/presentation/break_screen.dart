import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/models/break_session.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/exercise_log.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/countdown_timer.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../exercises/presentation/exercise_session_screen.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../pin_management/presentation/pin_entry_screen.dart';

class BreakScreen extends ConsumerStatefulWidget {
  final String packageName;

  const BreakScreen({super.key, required this.packageName});

  @override
  ConsumerState<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends ConsumerState<BreakScreen> {
  BreakSession? _session;
  MonitoredApp? _app;
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  int _totalBreakSeconds = 300;
  int _restSecondsRemaining = 300;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _loadBreakData();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _loadBreakData() async {
    final db = ref.read(databaseProvider);
    final breakService = ref.read(breakServiceProvider);

    final app = await db.getMonitoredApp(widget.packageName);
    final rule = await db.getRule(widget.packageName);
    final breakSec = (rule?.breakDurationMinutes ?? 5) * 60;

    final session = await breakService.requireBreak(
      packageName: widget.packageName,
      breakDurationSeconds: breakSec,
    );

    final allExercises = await db.getAllExercises();
    final requiredIds = rule?.exerciseIds.toSet() ?? {'pushups', 'squats', 'plank'};
    final filteredExercises = allExercises.where((e) => requiredIds.contains(e.id)).toList();

    if (mounted) {
      setState(() {
        _app = app;
        _session = session;
        _exercises = filteredExercises.isNotEmpty ? filteredExercises : allExercises.take(3).toList();
        _totalBreakSeconds = session.requiredBreakSeconds;
        _restSecondsRemaining = session.requiredBreakSeconds;
        _isLoading = false;
      });
      _startRestCountdown();
    }
  }

  void _startRestCountdown() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startExercises() async {
    if (_session == null) return;
    final breakService = ref.read(breakServiceProvider);
    await breakService.startExercises(_session!);

    if (!mounted) return;
    final logs = await Navigator.push<List<ExerciseLog>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseSessionScreen(
          requiredExercises: _exercises,
          packageName: widget.packageName,
          breakSessionId: _session!.id,
        ),
      ),
    );

    if (logs != null && mounted) {
      await breakService.completeExercises(_session!, logs);
      _promptPinEntry();
    }
  }

  void _promptPinEntry() async {
    final breakService = ref.read(breakServiceProvider);
    final monitor = ref.read(usageMonitorServiceProvider);

    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinEntryScreen(
          title: 'Final Step: Enter PIN',
          subtitle: 'Enter today\'s 8-digit PIN to release the break restriction.',
          onValidated: (pin) async {
            if (_session != null) {
              await breakService.validateAndUnlockBreak(_session!, pin);
              await monitor.releaseBreak(widget.packageName);
            }
          },
        ),
      ),
    );

    if (unlocked == true && mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.accentGreen),
            const SizedBox(height: Spacing.md),
            Text(
              'Break Completed!',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'You took a mindful rest and kept moving.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: Spacing.xl),
            EzzeButton(
              text: 'Resume App',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.brandRed)),
      );
    }

    final appName = _app?.appName ?? widget.packageName;

    return PopScope(
      canPop: false, // Non-dismissible as specified in Section 9.8
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
            children: [
              const SizedBox(height: Spacing.md),
              Center(
                child: AppIconView(
                  base64Icon: _app?.iconBase64,
                  fallbackLetter: appName,
                  size: 64,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Center(
                child: Text(
                  'BREAK REQUIRED',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Center(
                child: Text(
                  'Time to Step Away from $appName',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Center(
                child: Text(
                  'Continuous session limit reached. Take a physical rest before resuming.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: secondaryText),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Countdown Timer Hero Card
              EzzeCard(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                child: Center(
                  child: CountdownTimer(
                    totalSeconds: _totalBreakSeconds,
                    remainingSeconds: _restSecondsRemaining,
                    size: 190,
                    strokeWidth: 12,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Required Exercises Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Exercises',
                    style: AppTypography.titleLarge.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_exercises.length} activities',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              EzzeCard(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: Spacing.md),
                child: Column(
                  children: List.generate(_exercises.length, (index) {
                    final ex = _exercises[index];
                    final targetStr = ex.type == ExerciseType.repetitions
                        ? '${ex.defaultTarget} reps'
                        : '${ex.defaultTarget}s';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.brandRed.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            ex.name,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            ex.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(color: secondaryText),
                          ),
                          trailing: Text(
                            targetStr,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.brandRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (index < _exercises.length - 1) const Divider(),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Action Buttons
              EzzeButton(
                text: 'Start Exercises (${_exercises.length})',
                icon: Icons.play_arrow_rounded,
                onPressed: _startExercises,
              ),
              const SizedBox(height: Spacing.sm),
              EzzeButton(
                text: 'Enter 8-Digit PIN to Resume',
                variant: EzzeButtonVariant.secondary,
                icon: Icons.pin_rounded,
                onPressed: _promptPinEntry,
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
