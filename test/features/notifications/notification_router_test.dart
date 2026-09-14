import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_event_catalog.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRouter.resolveRoute', () {
    test('returns /notifications for null or empty payload', () {
      expect(NotificationRouter.resolveRoute(null), RoutePaths.notifications);
      expect(NotificationRouter.resolveRoute({}), RoutePaths.notifications);
    });

    test('routes home and general announcement destinations', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'home'}),
        RoutePaths.home,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'general_announcement'}),
        RoutePaths.home,
      );
    });

    test('routes notifications and service update destinations', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'notifications'}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({'destination': 'inbox'}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'service_update'}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'system'}),
        RoutePaths.notifications,
      );
    });

    test('routes ticket / booking with bookingId to QR screen', () {
      expect(
        NotificationRouter.resolveRoute({
          'screen': 'ticket',
          'booking_id': 'b-123',
        }),
        '/bookings/b-123/qr',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'booking_confirmed',
          'bookingId': 'b-456',
        }),
        '/bookings/b-456/qr',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'seat_changed',
          'booking_id': 'b-789',
        }),
        '/bookings/b-789/qr',
      );
    });

    test('routes ticket without bookingId to /trips', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'ticket'}),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'booking_cancelled'}),
        RoutePaths.trips,
      );
    });

    test('routes wallet, topup, refund, and credit destinations to /wallet', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'wallet'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'topup_approved'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'topup_rejected'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'wallet_credit'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'wallet_refund'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'screen': 'add_points'}),
        RoutePaths.wallet,
      );
    });

    test('routes live tracking / approaching / arrived / trip update destinations with tripId', () {
      expect(
        NotificationRouter.resolveRoute({
          'screen': 'live_tracking',
          'trip_id': 'trip-999',
        }),
        '/trips/trip-999/tracking',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'bus_approaching',
          'tripId': 'trip-888',
        }),
        '/trips/trip-888/tracking',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'bus_arrived_at_boarding_stop',
          'trip_id': 'trip-777',
        }),
        '/trips/trip-777/tracking',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'trip_update',
          'trip_id': 'trip-666',
        }),
        '/trips/trip-666/tracking',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'trip_delayed',
          'trip_id': 'trip-555',
        }),
        '/trips/trip-555/tracking',
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'next_stop_update',
          'trip_id': 'trip-444',
        }),
        '/trips/trip-444/tracking',
      );
    });

    test('routes live tracking without tripId to /live-map', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'live_map'}),
        RoutePaths.liveBusMap,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'bus_approaching'}),
        RoutePaths.liveBusMap,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'bus_arrived_at_boarding_stop'}),
        RoutePaths.liveBusMap,
      );
    });

    test('every catalog sample payload resolves to a valid application route', () {
      for (final event in NotificationEventCatalog.allEvents) {
        final route = NotificationRouter.resolveRoute(event.samplePayload);
        expect(route.startsWith('/'), isTrue,
            reason: '${event.eventType} payload resolved to invalid route: $route');
      }
    });

    test('falls back safely on unknown or unexpected keys', () {
      expect(
        NotificationRouter.resolveRoute({'random_key': 12345}),
        RoutePaths.notifications,
      );
    });
  });
}
