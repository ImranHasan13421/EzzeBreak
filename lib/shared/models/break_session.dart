enum BreakState {
  idle,
  breakRequired,
  breakInProgress,
  exerciseInProgress,
  awaitingPin,
  eligibleToResume,
  cancelledOrInvalidated;

  String get dbValue {
    switch (this) {
      case BreakState.idle:
        return 'idle';
      case BreakState.breakRequired:
        return 'break_required';
      case BreakState.breakInProgress:
        return 'break_in_progress';
      case BreakState.exerciseInProgress:
        return 'exercise_in_progress';
      case BreakState.awaitingPin:
        return 'awaiting_pin';
      case BreakState.eligibleToResume:
        return 'eligible_to_resume';
      case BreakState.cancelledOrInvalidated:
        return 'cancelled_or_invalidated';
    }
  }

  static BreakState fromDb(String? value) {
    switch (value) {
      case 'break_required':
        return BreakState.breakRequired;
      case 'break_in_progress':
        return BreakState.breakInProgress;
      case 'exercise_in_progress':
        return BreakState.exerciseInProgress;
      case 'awaiting_pin':
        return BreakState.awaitingPin;
      case 'eligible_to_resume':
        return BreakState.eligibleToResume;
      case 'cancelled_or_invalidated':
        return BreakState.cancelledOrInvalidated;
      case 'idle':
      default:
        return BreakState.idle;
    }
  }
}

class BreakSession {
  final String id;
  final String packageName;
  final DateTime triggerTime;
  final int requiredBreakSeconds;
  final BreakState currentState;
  final DateTime? completedTime;
  final bool pinValidated;
  final DateTime createdAt;

  BreakSession({
    required this.id,
    required this.packageName,
    required this.triggerTime,
    required this.requiredBreakSeconds,
    this.currentState = BreakState.breakRequired,
    this.completedTime,
    this.pinValidated = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BreakSession copyWith({
    String? id,
    String? packageName,
    DateTime? triggerTime,
    int? requiredBreakSeconds,
    BreakState? currentState,
    DateTime? completedTime,
    bool? pinValidated,
    DateTime? createdAt,
  }) {
    return BreakSession(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      triggerTime: triggerTime ?? this.triggerTime,
      requiredBreakSeconds: requiredBreakSeconds ?? this.requiredBreakSeconds,
      currentState: currentState ?? this.currentState,
      completedTime: completedTime ?? this.completedTime,
      pinValidated: pinValidated ?? this.pinValidated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_name': packageName,
      'trigger_time': triggerTime.millisecondsSinceEpoch,
      'required_break_seconds': requiredBreakSeconds,
      'current_state': currentState.dbValue,
      'completed_time': completedTime?.millisecondsSinceEpoch,
      'pin_validated': pinValidated ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BreakSession.fromMap(Map<String, dynamic> map) {
    return BreakSession(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      triggerTime: DateTime.fromMillisecondsSinceEpoch(map['trigger_time'] as int),
      requiredBreakSeconds: map['required_break_seconds'] as int,
      currentState: BreakState.fromDb(map['current_state'] as String?),
      completedTime: map['completed_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_time'] as int)
          : null,
      pinValidated: (map['pin_validated'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
