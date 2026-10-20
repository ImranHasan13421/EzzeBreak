class OverrideLog {
  final int? id;
  final String packageName;
  final int originalBudgetMinutes;
  final int usageAtAuthSeconds;
  final int extensionMinutes;
  final DateTime authorizedAt;
  final DateTime expiresAt;

  OverrideLog({
    this.id,
    required this.packageName,
    required this.originalBudgetMinutes,
    required this.usageAtAuthSeconds,
    required this.extensionMinutes,
    required this.authorizedAt,
    required this.expiresAt,
  });

  bool isExpired([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.isAfter(expiresAt);
  }

  Duration remainingExtension([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (current.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(current);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'original_budget_minutes': originalBudgetMinutes,
      'usage_at_auth_seconds': usageAtAuthSeconds,
      'extension_minutes': extensionMinutes,
      'authorized_at': authorizedAt.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    };
  }

  factory OverrideLog.fromMap(Map<String, dynamic> map) {
    return OverrideLog(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      originalBudgetMinutes: map['original_budget_minutes'] as int,
      usageAtAuthSeconds: map['usage_at_auth_seconds'] as int,
      extensionMinutes: map['extension_minutes'] as int,
      authorizedAt: DateTime.fromMillisecondsSinceEpoch(map['authorized_at'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
    );
  }
}
