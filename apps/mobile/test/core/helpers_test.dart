import 'package:flutter_test/flutter_test.dart';
import 'package:titanfit/core/utils/helpers.dart';

void main() {
  group('formatDuration', () {
    test('formats minutes-only durations', () {
      expect(formatDuration(null), '0m');
      expect(formatDuration(0), '0m');
      expect(formatDuration(45), '45m');
    });

    test('formats hour + minute durations', () {
      expect(formatDuration(60), '1h 0m');
      expect(formatDuration(95), '1h 35m');
      expect(formatDuration(130), '2h 10m');
    });
  });

  group('formatDate', () {
    test('formats dates with abbreviated month names', () {
      expect(formatDate(DateTime(2026, 8, 5)), 'Aug 5, 2026');
      expect(formatDate(DateTime(2026, 1, 31)), 'Jan 31, 2026');
      expect(formatDate(DateTime(2026, 12, 25)), 'Dec 25, 2026');
    });
  });

  group('formatTimeOfDay', () {
    test('uses 12-hour clock with AM/PM', () {
      expect(formatTimeOfDay(DateTime(2026, 8, 5, 0, 30)), '12:30 AM');
      expect(formatTimeOfDay(DateTime(2026, 8, 5, 9, 5)), '9:05 AM');
      expect(formatTimeOfDay(DateTime(2026, 8, 5, 12, 0)), '12:00 PM');
      expect(formatTimeOfDay(DateTime(2026, 8, 5, 15, 45)), '3:45 PM');
      expect(formatTimeOfDay(DateTime(2026, 8, 5, 23, 59)), '11:59 PM');
    });
  });

  group('greeting', () {
    test('returns the correct greeting for each period', () {
      expect(greeting(DateTime(2026, 8, 5, 8, 0)), 'Good morning');
      expect(greeting(DateTime(2026, 8, 5, 11, 59)), 'Good morning');
      expect(greeting(DateTime(2026, 8, 5, 12, 0)), 'Good afternoon');
      expect(greeting(DateTime(2026, 8, 5, 16, 59)), 'Good afternoon');
      expect(greeting(DateTime(2026, 8, 5, 17, 0)), 'Good evening');
      expect(greeting(DateTime(2026, 8, 5, 23, 59)), 'Good evening');
    });
  });
}
