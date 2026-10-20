import 'dart:convert';
import '../../core/constants/app_constants.dart';

class AppRule {
  final String packageName;
  final int dailyBudgetMinutes;
  final int sessionLimitMinutes;
  final int breakDurationMinutes;
  final List<String> exerciseIds;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppRule({
    required this.packageName,
    this.dailyBudgetMinutes = AppConstants.defaultDailyBudgetMinutes,
    this.sessionLimitMinutes = AppConstants.defaultSessionLimitMinutes,
    this.breakDurationMinutes = AppConstants.defaultBreakDurationMinutes,
    List<String>? exerciseIds,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : exerciseIds = exerciseIds ?? const ['pushups', 'squats', 'plank'],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppRule copyWith({
    String? packageName,
    int? dailyBudgetMinutes,
    int? sessionLimitMinutes,
    int? breakDurationMinutes,
    List<String>? exerciseIds,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppRule(
      packageName: packageName ?? this.packageName,
      dailyBudgetMinutes: dailyBudgetMinutes ?? this.dailyBudgetMinutes,
      sessionLimitMinutes: sessionLimitMinutes ?? this.sessionLimitMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'daily_budget_minutes': dailyBudgetMinutes,
      'session_limit_minutes': sessionLimitMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'exercise_ids_json': jsonEncode(exerciseIds),
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AppRule.fromMap(Map<String, dynamic> map) {
    List<String> parsedExercises = ['pushups', 'squats', 'plank'];
    final rawJson = map['exercise_ids_json'];
    if (rawJson is String && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          parsedExercises = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return AppRule(
      packageName: map['package_name'] as String,
      dailyBudgetMinutes: (map['daily_budget_minutes'] as int?) ?? AppConstants.defaultDailyBudgetMinutes,
      sessionLimitMinutes: (map['session_limit_minutes'] as int?) ?? AppConstants.defaultSessionLimitMinutes,
      breakDurationMinutes: (map['break_duration_minutes'] as int?) ?? AppConstants.defaultBreakDurationMinutes,
      exerciseIds: parsedExercises,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
