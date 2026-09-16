import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_payload_parser.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayloadParser.fromApnsPayload', () {
    test('parses simulator APNs alert and AMOMY routing data', () {
      final parsed = NotificationPayloadParser.fromApnsPayload({
        'aps': {
          'alert': {
            'title': 'AMOMY Bus',
            'body': 'This is an iOS simulator notification test.',
          },
          'sound': 'default',
          'badge': 1,
        },
        'type': 'trip_update',
        'notification_id': 'debug-ios-simulator-notification',
        'booking_id': 'debug-booking-001',
        'trip_id': 'debug-trip-001',
        'route': 'live_tracking',
      });

      expect(parsed.title, 'AMOMY Bus');
      expect(parsed.body, 'This is an iOS simulator notification test.');
      expect(parsed.data['type'], 'trip_update');
      expect(parsed.data['trip_id'], 'debug-trip-001');
      expect(parsed.data.containsKey('aps'), isFalse);
      expect(
        NotificationRouter.resolveRoute(parsed.data),
        '/trips/debug-trip-001/tracking',
      );
    });

    test('handles missing optional APNs fields without crashing', () {
      final parsed = NotificationPayloadParser.fromApnsPayload({
        'aps': <String, dynamic>{},
        'type': 'service_update',
      });

      expect(parsed.title, isNull);
      expect(parsed.body, isNull);
      expect(parsed.data['type'], 'service_update');
      expect(
        NotificationRouter.resolveRoute(parsed.data),
        RoutePaths.notifications,
      );
    });

    test('safely ignores unknown payloads for routing', () {
      final parsed = NotificationPayloadParser.fromApnsPayload({
        'aps': {'alert': 'A simple APNs alert string'},
        'unknown_key': 'unknown_value',
      });

      expect(parsed.title, isNull);
      expect(parsed.body, 'A simple APNs alert string');
      expect(
        NotificationRouter.resolveRoute(parsed.data),
        RoutePaths.notifications,
      );
    });
  });
}
