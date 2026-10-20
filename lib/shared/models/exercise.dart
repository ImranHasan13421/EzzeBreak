enum ExerciseType {
  repetitions,
  durationSeconds;

  String get dbValue => this == ExerciseType.repetitions ? 'repetitions' : 'duration_seconds';

  static ExerciseType fromDb(String? value) {
    return value == 'duration_seconds' ? ExerciseType.durationSeconds : ExerciseType.repetitions;
  }
}

class Exercise {
  final String id;
  final String name;
  final ExerciseType type;
  final int defaultTarget; // reps or seconds
  final String description;
  final bool isCustom;
  final bool isEnabled;

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.defaultTarget,
    this.description = '',
    this.isCustom = false,
    this.isEnabled = true,
  });

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    int? defaultTarget,
    String? description,
    bool? isCustom,
    bool? isEnabled,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultTarget: defaultTarget ?? this.defaultTarget,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.dbValue,
      'default_target': defaultTarget,
      'description': description,
      'is_custom': isCustom ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ExerciseType.fromDb(map['type'] as String?),
      defaultTarget: (map['default_target'] as int?) ?? 15,
      description: (map['description'] as String?) ?? '',
      isCustom: (map['is_custom'] as int?) == 1,
      isEnabled: (map['is_enabled'] as int?) == 1,
    );
  }

  static List<Exercise> defaultExercises() {
    return const [
      Exercise(
        id: 'pushups',
        name: 'Push-ups',
        type: ExerciseType.repetitions,
        defaultTarget: 15,
        description: 'Upper body and core strength.',
      ),
      Exercise(
        id: 'situps',
        name: 'Sit-ups',
        type: ExerciseType.repetitions,
        defaultTarget: 20,
        description: 'Abdominal and core endurance.',
      ),
      Exercise(
        id: 'squats',
        name: 'Squats',
        type: ExerciseType.repetitions,
        defaultTarget: 20,
        description: 'Lower body and posture reactivation.',
      ),
      Exercise(
        id: 'pullups',
        name: 'Pull-ups',
        type: ExerciseType.repetitions,
        defaultTarget: 8,
        description: 'Back and bicep upper body pull.',
      ),
      Exercise(
        id: 'jumping_jacks',
        name: 'Jumping Jacks',
        type: ExerciseType.repetitions,
        defaultTarget: 30,
        description: 'Quick cardio boost to get blood flowing.',
      ),
      Exercise(
        id: 'lunges',
        name: 'Lunges',
        type: ExerciseType.repetitions,
        defaultTarget: 16,
        description: 'Single leg balance and quadriceps focus.',
      ),
      Exercise(
        id: 'plank',
        name: 'Plank',
        type: ExerciseType.durationSeconds,
        defaultTarget: 45,
        description: 'Isometric core stability holds.',
      ),
      Exercise(
        id: 'stretching',
        name: 'Stretching',
        type: ExerciseType.durationSeconds,
        defaultTarget: 60,
        description: 'Gentle neck, shoulder and back mobility.',
      ),
      Exercise(
        id: 'walking',
        name: 'Walking',
        type: ExerciseType.durationSeconds,
        defaultTarget: 120,
        description: 'Pacing or stepping around the room.',
      ),
    ];
  }
}
