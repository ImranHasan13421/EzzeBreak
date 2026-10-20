class ExerciseLog {
  final int? id;
  final String exerciseId;
  final String exerciseName;
  final int repetitions;
  final int durationSeconds;
  final String? breakSessionId;
  final String? packageName;
  final bool isConfirmed;
  final DateTime completedAt;

  ExerciseLog({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.repetitions = 0,
    this.durationSeconds = 0,
    this.breakSessionId,
    this.packageName,
    this.isConfirmed = true,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'repetitions': repetitions,
      'duration_seconds': durationSeconds,
      'break_session_id': breakSessionId,
      'package_name': packageName,
      'is_confirmed': isConfirmed ? 1 : 0,
      'completed_at': completedAt.millisecondsSinceEpoch,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      repetitions: (map['repetitions'] as int?) ?? 0,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      breakSessionId: map['break_session_id'] as String?,
      packageName: map['package_name'] as String?,
      isConfirmed: (map['is_confirmed'] as int?) == 1,
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
    );
  }
}
