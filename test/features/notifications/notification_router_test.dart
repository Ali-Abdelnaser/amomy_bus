import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRouter.resolveRoute', () {
    test('returns /notifications for null or empty payload', () {
      expect(NotificationRouter.resolveRoute(null), RoutePaths.notifications);
      expect(NotificationRouter.resolveRoute({}), RoutePaths.notifications);
    });

    test('routes home destination', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'home'}),
        RoutePaths.home,
      );
    });

    test('routes notifications destination', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'notifications'}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({'destination': 'inbox'}),
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
    });

    test('routes ticket without bookingId to /trips', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'ticket'}),
        RoutePaths.trips,
      );
    });

    test('routes wallet and topup destinations to /wallet', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'wallet'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'topup_approved'}),
        RoutePaths.wallet,
      );
      expect(
        NotificationRouter.resolveRoute({'screen': 'add_points'}),
        RoutePaths.wallet,
      );
    });

    test('routes live tracking / approaching destination with tripId', () {
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
    });

    test('routes live tracking without tripId to /live-map', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'live_map'}),
        RoutePaths.liveBusMap,
      );
    });

    test('falls back safely on unknown or unexpected keys', () {
      expect(
        NotificationRouter.resolveRoute({'random_key': 12345}),
        RoutePaths.notifications,
      );
    });
  });
}
