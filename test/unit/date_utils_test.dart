import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_break/core/utils/date_utils.dart';
import 'package:ezze_break/core/utils/formatters.dart';

void main() {
  group('EzzeDateUtils and EzzeFormatters Tests', () {
    test('dateKey formats yyyy-MM-dd correctly', () {
      final date = DateTime(2026, 10, 20, 14, 30);
      expect(EzzeDateUtils.dateKey(date), '2026-10-20');
    });

    test('parseDateKey parses yyyy-MM-dd correctly', () {
      final parsed = EzzeDateUtils.parseDateKey('2026-10-20');
      expect(parsed.year, 2026);
      expect(parsed.month, 10);
      expect(parsed.day, 20);
    });

    test('startOfDay returns midnight', () {
      final date = DateTime(2026, 10, 20, 15, 45, 12);
      final sod = EzzeDateUtils.startOfDay(date);
      expect(sod.hour, 0);
      expect(sod.minute, 0);
      expect(sod.second, 0);
      expect(sod.millisecond, 0);
    });

    test('lastNDaysKeys returns correct count of consecutive days', () {
      final keys = EzzeDateUtils.lastNDaysKeys(7);
      expect(keys.length, 7);
      expect(keys.last, EzzeDateUtils.todayKey());
    });

    test('formatSeconds formats hours, minutes, and seconds', () {
      expect(EzzeFormatters.formatSeconds(0), '0m');
      expect(EzzeFormatters.formatSeconds(45), '45s');
      expect(EzzeFormatters.formatSeconds(125), '2m');
      expect(EzzeFormatters.formatSeconds(3600), '1h');
      expect(EzzeFormatters.formatSeconds(5400), '1h 30m');
    });

    test('formatMinutes formats hours and minutes', () {
      expect(EzzeFormatters.formatMinutes(0), '0 min');
      expect(EzzeFormatters.formatMinutes(45), '45 min');
      expect(EzzeFormatters.formatMinutes(60), '1 hr');
      expect(EzzeFormatters.formatMinutes(90), '1 hr 30 min');
    });

    test('formatCountdown formats MM:SS', () {
      expect(EzzeFormatters.formatCountdown(0), '00:00');
      expect(EzzeFormatters.formatCountdown(65), '01:05');
      expect(EzzeFormatters.formatCountdown(300), '05:00');
    });

    test('formatPercentage clamps and formats', () {
      expect(EzzeFormatters.formatPercentage(0.0), '0%');
      expect(EzzeFormatters.formatPercentage(0.456), '46%');
      expect(EzzeFormatters.formatPercentage(1.0), '100%');
      expect(EzzeFormatters.formatPercentage(1.5), '100%');
    });
  });
}
