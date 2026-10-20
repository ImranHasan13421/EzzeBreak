class PinState {
  final String currentPin;
  final DateTime windowStart;
  final DateTime windowExpires;
  final DateTime updatedAt;

  PinState({
    required this.currentPin,
    required this.windowStart,
    required this.windowExpires,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool isExpired([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.isAfter(windowExpires);
  }

  Duration remainingValidity([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (current.isAfter(windowExpires)) return Duration.zero;
    return windowExpires.difference(current);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'current_pin': currentPin,
      'window_start': windowStart.millisecondsSinceEpoch,
      'window_expires': windowExpires.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory PinState.fromMap(Map<String, dynamic> map) {
    return PinState(
      currentPin: map['current_pin'] as String,
      windowStart: DateTime.fromMillisecondsSinceEpoch(map['window_start'] as int),
      windowExpires: DateTime.fromMillisecondsSinceEpoch(map['window_expires'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
