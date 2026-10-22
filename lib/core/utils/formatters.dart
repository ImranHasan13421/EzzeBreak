class EzzeFormatters {
  /// Format seconds into readable string: e.g. "1h 24m", "42m", "15s"
  static String formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '${seconds}s';
  }

  /// Format minutes into readable string: e.g. "1 hr 30 min", "45 min"
  static String formatMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0 min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hr';
    }
    return '$minutes min';
  }

  /// Format clock countdown (MM:SS)
  static String formatCountdown(int remainingSeconds) {
    if (remainingSeconds < 0) remainingSeconds = 0;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format percentage: e.g. "65%"
  static String formatPercentage(double ratio) {
    final pct = (ratio * 100).clamp(0, 100).round();
    return '$pct%';
  }

  /// Compact formatting for gauges and badges: e.g. "1h 15m", "45m", "3h", "0m"
  static String formatCompact(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }
}

typedef Formatters = EzzeFormatters;
