import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'subscribeToTripSeatUpdates uses trip_seat_state only for seat invalidation',
    () {
      final source = File(
        'lib/features/booking/data/datasources/booking_remote_data_source.dart',
      ).readAsStringSync();

      final method = _methodBody(
        source,
        'Stream<void> subscribeToTripSeatUpdates',
      );

      expect(method, contains("table: 'trip_seat_state'"));
      expect(method, contains("column: 'trip_id'"));
      expect(method, isNot(contains("table: 'seat_holds'")));
      expect(method, isNot(contains("table: 'bookings'")));
    },
  );

  test('all passenger seat-map surfaces use the shared trip seat stream', () {
    final files = {
      'normal seat selection':
          'lib/features/booking/presentation/cubit/booking_cubit.dart',
      'change seat modal':
          'lib/features/trips/presentation/widgets/change_seat_modal.dart',
      'change seat page':
          'lib/features/trips/presentation/pages/change_seat_page.dart',
      'extra seat modal':
          'lib/features/trips/presentation/widgets/add_extra_seat_modal.dart',
    };

    for (final entry in files.entries) {
      final source = File(entry.value).readAsStringSync();
      expect(
        source,
        contains('subscribeToTripSeatUpdates'),
        reason: '${entry.key} should use trip_seat_state invalidation',
      );
    }
  });
}

String _methodBody(String source, String signature) {
  final implementationStart = source.indexOf(
    'class BookingRemoteDataSourceImpl',
  );
  expect(
    implementationStart,
    isNonNegative,
    reason: 'Missing BookingRemoteDataSourceImpl',
  );

  final start = source.indexOf(signature, implementationStart);
  expect(start, isNonNegative, reason: 'Missing $signature');

  final openBrace = source.indexOf('{', start);
  expect(openBrace, isNonNegative, reason: 'Missing method body');

  var depth = 0;
  for (var index = openBrace; index < source.length; index++) {
    final char = source[index];
    if (char == '{') depth++;
    if (char == '}') depth--;
    if (depth == 0) {
      return source.substring(openBrace, index + 1);
    }
  }

  fail('Unterminated method body for $signature');
}
