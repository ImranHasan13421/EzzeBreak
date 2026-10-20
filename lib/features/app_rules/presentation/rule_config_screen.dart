import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/app_rule.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/monitored_app.dart';
import '../../../shared/widgets/app_icon_view.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class RuleConfigScreen extends ConsumerStatefulWidget {
  final MonitoredApp app;
  final AppRule? initialRule;

  const RuleConfigScreen({
    super.key,
    required this.app,
    this.initialRule,
  });

  @override
  ConsumerState<RuleConfigScreen> createState() => _RuleConfigScreenState();
}

class _RuleConfigScreenState extends ConsumerState<RuleConfigScreen> {
  late int _dailyBudgetMinutes;
  late int _sessionLimitMinutes;
  late int _breakDurationMinutes;
  late Set<String> _selectedExerciseIds;
  late bool _isEnabled;
  List<Exercise> _allExercises = [];
  bool _isLoadingExercises = true;

  final List<int> _budgetPresets = [30, 60, 90, 120, 180, 240];
  final List<int> _sessionPresets = [15, 20, 30, 45, 60];
  final List<int> _breakPresets = [2, 3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule ?? AppRule(packageName: widget.app.packageName);
    _dailyBudgetMinutes = rule.dailyBudgetMinutes;
    _sessionLimitMinutes = rule.sessionLimitMinutes;
    _breakDurationMinutes = rule.breakDurationMinutes;
    _selectedExerciseIds = rule.exerciseIds.toSet();
    _isEnabled = rule.isEnabled;

    _loadExercises();
  }

  void _loadExercises() async {
    final db = ref.read(databaseProvider);
    final list = await db.getAllExercises();
    if (mounted) {
      setState(() {
        _allExercises = list;
        _isLoadingExercises = false;
      });
    }
  }

  void _save() async {
    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one exercise for breaks.')),
      );
      return;
    }

    final updatedRule = AppRule(
      packageName: widget.app.packageName,
      dailyBudgetMinutes: _dailyBudgetMinutes,
      sessionLimitMinutes: _sessionLimitMinutes,
      breakDurationMinutes: _breakDurationMinutes,
      exerciseIds: _selectedExerciseIds.toList(),
      isEnabled: _isEnabled,
      updatedAt: DateTime.now(),
    );

    await ref.read(appRulesMapProvider.notifier).saveRule(updatedRule);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rules saved for ${widget.app.appName}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('App Rules', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.brandRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
        children: [
          // Hero App Header Card
          EzzeCard(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                AppIconView(
                  base64Icon: widget.app.iconBase64,
                  fallbackLetter: widget.app.appName,
                  size: 56,
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.app.appName,
                        style: AppTypography.headlineSmall.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.app.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: Spacing.xs),
                      StatusBadge(
                        label: _isEnabled ? 'Active' : 'Paused',
                        type: _isEnabled ? BadgeType.active : BadgeType.neutral,
                        showDot: true,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  activeThumbColor: AppColors.brandRed,
                  onChanged: (val) => setState(() => _isEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),

          // 1. Daily Budget Section
          _buildSectionTitle('Daily Screen Budget', 'Total daily screen time before lockdown.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Allowance', style: AppTypography.titleSmall.copyWith(color: secondaryText)),
                    Text(
                      Formatters.formatMinutes(_dailyBudgetMinutes),
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _dailyBudgetMinutes.toDouble().clamp(15.0, 360.0),
                  min: 15.0,
                  max: 360.0,
                  divisions: 23,
                  activeColor: AppColors.brandRed,
                  inactiveColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                  onChanged: (val) {
                    setState(() => _dailyBudgetMinutes = val.round());
                  },
                ),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: _budgetPresets.map((mins) {
                    final isSel = _dailyBudgetMinutes == mins;
                    return ChoiceChip(
                      label: Text(mins < 60 ? '${mins}m' : '${mins ~/ 60}h ${mins % 60 > 0 ? '${mins % 60}m' : ''}'),
                      selected: isSel,
                      selectedColor: AppColors.brandRed.withValues(alpha: 0.18),
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: isSel ? AppColors.brandRed : primaryText,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _dailyBudgetMinutes = mins),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // 2. Continuous Session Limit
          _buildSectionTitle('Continuous Session Limit', 'Screen time before a mandatory physical break triggers.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Session Timeout', style: AppTypography.titleSmall.copyWith(color: secondaryText)),
                    Text(
                      '$_sessionLimitMinutes min',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _sessionLimitMinutes.toDouble().clamp(5.0, 120.0),
                  min: 5.0,
                  max: 120.0,
                  divisions: 23,
                  activeColor: AppColors.brandRed,
                  inactiveColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                  onChanged: (val) {
                    setState(() => _sessionLimitMinutes = val.round());
                  },
                ),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: _sessionPresets.map((mins) {
                    final isSel = _sessionLimitMinutes == mins;
                    return ChoiceChip(
                      label: Text('${mins}m'),
                      selected: isSel,
                      selectedColor: AppColors.brandRed.withValues(alpha: 0.18),
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: isSel ? AppColors.brandRed : primaryText,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _sessionLimitMinutes = mins),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // 3. Break Duration
          _buildSectionTitle('Break Rest Duration', 'Mandatory rest countdown period during breaks.'),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rest Timer', style: AppTypography.titleSmall.copyWith(color: secondaryText)),
                    Text(
                      '$_breakDurationMinutes min',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _breakDurationMinutes.toDouble().clamp(1.0, 30.0),
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  activeColor: AppColors.brandRed,
                  inactiveColor: isDark ? AppColors.darkBg3 : AppColors.lightBg3,
                  onChanged: (val) {
                    setState(() => _breakDurationMinutes = val.round());
                  },
                ),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: _breakPresets.map((mins) {
                    final isSel = _breakDurationMinutes == mins;
                    return ChoiceChip(
                      label: Text('${mins}m'),
                      selected: isSel,
                      selectedColor: AppColors.brandRed.withValues(alpha: 0.18),
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: isSel ? AppColors.brandRed : primaryText,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _breakDurationMinutes = mins),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // 4. Required Exercises Section
          _buildSectionTitle('Required Physical Exercises', 'Exercises required during breaks before unlocking.'),
          const SizedBox(height: Spacing.sm),
          _isLoadingExercises
              ? const Center(child: CircularProgressIndicator())
              : EzzeCard(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Column(
                    children: _allExercises.map((exercise) {
                      final isSelected = _selectedExerciseIds.contains(exercise.id);
                      final targetStr = exercise.type == ExerciseType.repetitions
                          ? '${exercise.defaultTarget} reps'
                          : '${exercise.defaultTarget}s';

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppColors.brandRed,
                        title: Text(
                          exercise.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$targetStr • ${exercise.description}',
                          style: AppTypography.bodySmall.copyWith(color: secondaryText),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedExerciseIds.add(exercise.id);
                            } else {
                              _selectedExerciseIds.remove(exercise.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
          const SizedBox(height: Spacing.xxl),

          EzzeButton(
            text: 'Save Rule Settings',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: Spacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
      ],
    );
  }
}
