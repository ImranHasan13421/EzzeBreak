class DailyUsage {
  final int? id;
  final String packageName;
  final String dateKey;
  final int accumulatedSeconds;
  final int allowanceMinutes;
  final int additionalSeconds;
  final DateTime updatedAt;

  DailyUsage({
    this.id,
    required this.packageName,
    required this.dateKey,
    this.accumulatedSeconds = 0,
    this.allowanceMinutes = 60,
    this.additionalSeconds = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get allowanceSeconds => allowanceMinutes * 60;
  int get totalAllowanceSeconds => allowanceSeconds + additionalSeconds;

  int get remainingSeconds {
    final rem = totalAllowanceSeconds - accumulatedSeconds;
    return rem > 0 ? rem : 0;
  }

  bool get isOverBudget => accumulatedSeconds >= totalAllowanceSeconds;

  double get usageRatio {
    if (totalAllowanceSeconds <= 0) return 1.0;
    return (accumulatedSeconds / totalAllowanceSeconds).clamp(0.0, 1.0);
  }

  DailyUsage copyWith({
    int? id,
    String? packageName,
    String? dateKey,
    int? accumulatedSeconds,
    int? allowanceMinutes,
    int? additionalSeconds,
    DateTime? updatedAt,
  }) {
    return DailyUsage(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      dateKey: dateKey ?? this.dateKey,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      allowanceMinutes: allowanceMinutes ?? this.allowanceMinutes,
      additionalSeconds: additionalSeconds ?? this.additionalSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'date_key': dateKey,
      'accumulated_seconds': accumulatedSeconds,
      'allowance_minutes': allowanceMinutes,
      'additional_seconds': additionalSeconds,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DailyUsage.fromMap(Map<String, dynamic> map) {
    return DailyUsage(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      dateKey: map['date_key'] as String,
      accumulatedSeconds: (map['accumulated_seconds'] as int?) ?? 0,
      allowanceMinutes: (map['allowance_minutes'] as int?) ?? 60,
      additionalSeconds: (map['additional_seconds'] as int?) ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
