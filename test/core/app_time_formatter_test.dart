import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/localization/app_time_formatter.dart';

void main() {
  group('AppTimeFormatter Tests', () {
    test(
      'A. Outbound trips format correctly in English (8:00 AM - 11:00 AM)',
      () {
        expect(
          AppTimeFormatter.formatDepartureTime(
            departureAt: DateTime(2026, 9, 16, 8, 0),
            locale: 'en',
          ),
          '8:00 AM',
        );
        expect(
          AppTimeFormatter.formatDepartureTime(
            departureAt: DateTime(2026, 9, 16, 9, 0),
            locale: 'en',
          ),
          '9:00 AM',
        );
        expect(
          AppTimeFormatter.formatDepartureTime(
            departureAt: DateTime(2026, 9, 16, 10, 0),
            locale: 'en',
          ),
          '10:00 AM',
        );
        expect(
          AppTimeFormatter.formatDepartureTime(
            departureAt: DateTime(2026, 9, 16, 11, 0),
            locale: 'en',
          ),
          '11:00 AM',
        );
      },
    );

    test('B. Return trips format correctly in English (1:00 PM - 4:00 PM)', () {
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 13, 0),
          locale: 'en',
        ),
        '1:00 PM',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 14, 0),
          locale: 'en',
        ),
        '2:00 PM',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 15, 0),
          locale: 'en',
        ),
        '3:00 PM',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 16, 0),
          locale: 'en',
        ),
        '4:00 PM',
      );
    });

    test('C. Arabic equivalent renders without 24-hour 13/14/15/16 labels', () {
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 8, 0),
          locale: 'ar',
        ),
        '8:00 ص',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 13, 0),
          locale: 'ar',
        ),
        '1:00 م',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 14, 0),
          locale: 'ar',
        ),
        '2:00 م',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 15, 0),
          locale: 'ar',
        ),
        '3:00 م',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime(2026, 9, 16, 16, 0),
          locale: 'ar',
        ),
        '4:00 م',
      );

      // Verify no 24-hour strings appear
      final arReturn = AppTimeFormatter.formatDepartureTime(
        departureAt: DateTime(2026, 9, 16, 13, 0),
        locale: 'ar',
      );
      expect(arReturn.contains('13'), isFalse);
    });

    test('Fallback parsing when departureAt is null', () {
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureTime: '08:00',
          locale: 'en',
        ),
        '8:00 AM',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureTime: '13:00',
          locale: 'en',
        ),
        '1:00 PM',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureTime: '16:30',
          locale: 'ar',
        ),
        '4:30 م',
      );
    });
  });
}
