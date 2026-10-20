class AppUsageStat {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final int usageSeconds;
  final int budgetMinutes;
  final int sessionsCount;
  final int breaksCount;
  final int overridesCount;

  AppUsageStat({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    required this.usageSeconds,
    required this.budgetMinutes,
    this.sessionsCount = 0,
    this.breaksCount = 0,
    this.overridesCount = 0,
  });

  double get budgetRatio {
    final budgetSec = budgetMinutes * 60;
    if (budgetSec <= 0) return 0.0;
    return (usageSeconds / budgetSec).clamp(0.0, 1.0);
  }
}

class DailyTrendItem {
  final String dateKey;
  final int usageSeconds;
  final int breaksCount;
  final int exercisesCount;

  DailyTrendItem({
    required this.dateKey,
    required this.usageSeconds,
    required this.breaksCount,
    required this.exercisesCount,
  });
}

class ExerciseSummaryItem {
  final String exerciseName;
  final String type; // 'repetitions' or 'duration_seconds'
  final int totalRepetitions;
  final int totalDurationSeconds;
  final int sessionCount;

  ExerciseSummaryItem({
    required this.exerciseName,
    required this.type,
    this.totalRepetitions = 0,
    this.totalDurationSeconds = 0,
    this.sessionCount = 0,
  });
}

class AnalyticsSummary {
  final String periodTitle;
  final int totalUsageSeconds;
  final int monitoredAppsCount;
  final int breaksTriggered;
  final int breaksCompleted;
  final int exercisesCompleted;
  final int totalRepetitions;
  final int totalExerciseSeconds;
  final int overridesCount;
  final int totalOverrideMinutes;
  final List<AppUsageStat> appStats;
  final List<DailyTrendItem> dailyTrends;
  final List<ExerciseSummaryItem> exerciseStats;

  AnalyticsSummary({
    required this.periodTitle,
    required this.totalUsageSeconds,
    required this.monitoredAppsCount,
    required this.breaksTriggered,
    required this.breaksCompleted,
    required this.exercisesCompleted,
    required this.totalRepetitions,
    required this.totalExerciseSeconds,
    required this.overridesCount,
    required this.totalOverrideMinutes,
    required this.appStats,
    required this.dailyTrends,
    required this.exerciseStats,
  });
}
