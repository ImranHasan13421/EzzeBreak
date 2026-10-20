import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/exercise_log.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final List<Exercise> requiredExercises;
  final String packageName;
  final String breakSessionId;

  const ExerciseSessionScreen({
    super.key,
    required this.requiredExercises,
    required this.packageName,
    required this.breakSessionId,
  });

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  int _currentIndex = 0;
  bool _isResting = false;
  int _restSecondsRemaining = 15;
  Timer? _timer;

  // Active timed exercise timer
  int _timedSecondsRemaining = 0;

  final List<ExerciseLog> _completedLogs = [];

  Exercise get currentExercise => widget.requiredExercises[_currentIndex];

  @override
  void initState() {
    super.initState();
    _setupExercise(currentExercise);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupExercise(Exercise ex) {
    _timer?.cancel();
    _isResting = false;
    if (ex.type == ExerciseType.durationSeconds) {
      _timedSecondsRemaining = ex.defaultTarget;
      _startExerciseTimer();
    }
  }

  void _startExerciseTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timedSecondsRemaining > 0) {
        setState(() => _timedSecondsRemaining--);
      } else {
        timer.cancel();
        _onExerciseFinished();
      }
    });
  }

  void _onExerciseFinished() {
    final ex = currentExercise;
    final log = ExerciseLog(
      exerciseId: ex.id,
      exerciseName: ex.name,
      repetitions: ex.type == ExerciseType.repetitions ? ex.defaultTarget : 0,
      durationSeconds: ex.type == ExerciseType.durationSeconds ? ex.defaultTarget : 0,
      breakSessionId: widget.breakSessionId,
      packageName: widget.packageName,
      isConfirmed: true,
      completedAt: DateTime.now(),
    );
    _completedLogs.add(log);

    if (_currentIndex + 1 < widget.requiredExercises.length) {
      // Start 15-second rest between exercises
      setState(() {
        _isResting = true;
        _restSecondsRemaining = 15;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_restSecondsRemaining > 0) {
          setState(() => _restSecondsRemaining--);
        } else {
          timer.cancel();
          _nextExercise();
        }
      });
    } else {
      // All exercises completed
      Navigator.pop(context, _completedLogs);
    }
  }

  void _nextExercise() {
    _timer?.cancel();
    setState(() {
      _currentIndex++;
      _setupExercise(widget.requiredExercises[_currentIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercise ${_currentIndex + 1} of ${widget.requiredExercises.length}',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
          child: Column(
            children: [
              // Progress Bar & Dot Indicators
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.xs),
                child: LinearProgressIndicator(
                  value: (_currentIndex + (_isResting ? 0.5 : 0)) / widget.requiredExercises.length,
                  backgroundColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandRed),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.requiredExercises.length, (idx) {
                  final isDone = idx < _currentIndex;
                  final isCurrent = idx == _currentIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.accentGreen
                          : (isCurrent
                              ? AppColors.brandRed
                              : (isDark ? AppColors.darkBg3 : AppColors.lightBg3)),
                      borderRadius: BorderRadius.circular(Radii.full),
                    ),
                  );
                }),
              ),
              const SizedBox(height: Spacing.xxl),

              // Rest Mode vs Active Mode
              if (_isResting) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(Spacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    size: 64,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  'Rest & Breathe',
                  style: AppTypography.headlineMedium.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Take deep breaths before the next movement.',
                  style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  '00:${_restSecondsRemaining.toString().padLeft(2, '0')}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 48,
                    color: AppColors.accentGreen,
                  ),
                ),
                const Spacer(),
                EzzeButton(
                  text: 'Skip Rest Period',
                  variant: EzzeButtonVariant.secondary,
                  onPressed: _nextExercise,
                ),
              ] else ...[
                // Active Exercise View
                Text(
                  currentExercise.name,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  currentExercise.description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: secondaryText),
                ),
                const Spacer(),

                // Target Display
                if (currentExercise.type == ExerciseType.repetitions) ...[
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brandRed, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandRed.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentExercise.defaultTarget}',
                          style: AppTypography.mono.copyWith(
                            fontSize: 54,
                            color: AppColors.brandRed,
                          ),
                        ),
                        Text(
                          'REPS',
                          style: AppTypography.labelLarge.copyWith(
                            color: secondaryText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Timed Duration
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brandRed, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandRed.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Formatters.formatCountdown(_timedSecondsRemaining),
                          style: AppTypography.mono.copyWith(
                            fontSize: 42,
                            color: AppColors.brandRed,
                          ),
                        ),
                        Text(
                          'REMAINING',
                          style: AppTypography.labelSmall.copyWith(
                            color: secondaryText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                EzzeButton(
                  text: _currentIndex + 1 == widget.requiredExercises.length
                      ? '✓ Complete All Exercises'
                      : '✓ Done, Next Exercise',
                  onPressed: _onExerciseFinished,
                ),
              ],

              const SizedBox(height: Spacing.md),
              // Upcoming exercise preview
              EzzeCard(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.checklist_rounded, size: 18, color: AppColors.brandRed),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'Upcoming: ${widget.requiredExercises.skip(_currentIndex + 1).map((e) => e.name).join(', ').isEmpty ? 'Final Exercise!' : widget.requiredExercises.skip(_currentIndex + 1).map((e) => e.name).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
