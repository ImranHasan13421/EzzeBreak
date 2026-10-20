import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/exercise_log.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Exercise> _exercises = [];
  List<ExerciseLog> _recentLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final db = ref.read(databaseProvider);
    final exercises = await db.getAllExercises();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final logs = await db.getExerciseLogsForDateRange(start, now);

    if (mounted) {
      setState(() {
        _exercises = exercises;
        _recentLogs = logs;
        _isLoading = false;
      });
    }
  }

  void _showAddCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '15');
    final descCtrl = TextEditingController();
    ExerciseType selectedType = ExerciseType.repetitions;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'Add Custom Exercise',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name',
                      hintText: 'e.g. Wall Sit, Arm Circles',
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Reps'),
                          selected: selectedType == ExerciseType.repetitions,
                          selectedColor: AppColors.brandRed.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: selectedType == ExerciseType.repetitions
                                ? AppColors.brandRed
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(
                            () => selectedType = ExerciseType.repetitions,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Duration'),
                          selected: selectedType == ExerciseType.durationSeconds,
                          selectedColor: AppColors.brandRed.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: selectedType == ExerciseType.durationSeconds
                                ? AppColors.brandRed
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(
                            () => selectedType = ExerciseType.durationSeconds,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: selectedType == ExerciseType.repetitions
                          ? 'Default Repetitions'
                          : 'Default Duration (Seconds)',
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description / Instructions',
                      hintText: 'Optional coaching tip',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final target = int.tryParse(targetCtrl.text.trim()) ?? 15;
                  if (name.isEmpty) return;

                  final nav = Navigator.of(ctx);
                  final db = ref.read(databaseProvider);
                  final newEx = Exercise(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    type: selectedType,
                    defaultTarget: target,
                    description: descCtrl.text.trim(),
                    isCustom: true,
                  );
                  await db.upsertExercise(newEx);
                  nav.pop();
                  _loadData();
                },
                child: const Text('Add Exercise'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCustomExercise(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteCustomExercise(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercise Library',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brandRed,
          unselectedLabelColor: secondaryText,
          indicatorColor: AppColors.brandRed,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Routines'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandRed))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Exercise Routines
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Exercises (${_exercises.length})',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _showAddCustomExerciseDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Custom'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    ..._exercises.map((ex) {
                      final targetStr = ex.type == ExerciseType.repetitions
                          ? '${ex.defaultTarget} reps'
                          : '${ex.defaultTarget}s';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: EzzeCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(Spacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.brandRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: Icon(
                                  ex.type == ExerciseType.repetitions
                                      ? Icons.fitness_center_rounded
                                      : Icons.timer_outlined,
                                  color: AppColors.brandRed,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            ex.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMedium.copyWith(
                                              color: primaryText,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (ex.isCustom) ...[
                                          const SizedBox(width: Spacing.xs),
                                          const StatusBadge(label: 'Custom', type: BadgeType.neutral),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ex.description,
                                      style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    targetStr,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.brandRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (ex.isCustom) ...[
                                    const SizedBox(height: Spacing.xs),
                                    InkWell(
                                      onTap: () => _deleteCustomExercise(ex.id),
                                      borderRadius: BorderRadius.circular(Radii.xs),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                // Tab 2: Recent History
                _recentLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 54, color: secondaryText),
                            const SizedBox(height: Spacing.md),
                            Text(
                              'No exercises logged yet',
                              style: AppTypography.titleLarge.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Complete break sessions to log your daily physical movement.',
                              style: AppTypography.bodySmall.copyWith(color: secondaryText),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
                        itemCount: _recentLogs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                        itemBuilder: (context, index) {
                          final log = _recentLogs[index];
                          final activity = log.repetitions > 0
                              ? '${log.repetitions} reps'
                              : Formatters.formatSeconds(log.durationSeconds);

                          return EzzeCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(Spacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: AppColors.accentGreen, size: 18),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.exerciseName,
                                        style: AppTypography.titleMedium.copyWith(
                                          color: primaryText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        EzzeDateUtils.formatPretty(log.completedAt),
                                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  activity,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.brandRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
