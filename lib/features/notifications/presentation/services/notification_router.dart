import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_paths.dart';
import 'notification_payload_parser.dart';

class NotificationRouter {
  NotificationRouter._();

  /// Resolves the destination route path from a notification data payload.
  /// Falls back safely to '/notifications' or '/home' on unknown or malformed payloads.
  static String resolveRoute(Map<String, dynamic>? data) {
    final routingData = NotificationPayloadParser.routingDataFrom(data);
    if (routingData.isEmpty) {
      return RoutePaths.notifications;
    }

    try {
      final screen =
          (routingData['screen'] ??
                  routingData['destination'] ??
                  routingData['route'] ??
                  routingData['type'])
              ?.toString()
              .toLowerCase()
              .trim();

      final bookingId = (routingData['booking_id'] ?? routingData['bookingId'])
          ?.toString()
          .trim();
      final tripId = (routingData['trip_id'] ?? routingData['tripId'])
          ?.toString()
          .trim();

      if (_isBookingQrRoute(screen) || _isBookingLifecyclePayload(screen)) {
        return RoutePaths.trips;
      }

      if (_isBookingRefundPayload(screen, bookingId: bookingId)) {
        return RoutePaths.trips;
      }

      // Explicit route matching
      switch (screen) {
        case 'home':
        case 'general_announcement':
          return RoutePaths.home;

        case 'notifications':
        case 'inbox':
        case 'system':
        case 'service_update':
          return RoutePaths.notifications;

        case 'ticket':
        case 'booking':
        case 'booking_qr':
        case 'booking_confirmed':
        case 'seat_changed':
        case 'trips':
        case 'my_trips':
        case 'booking_cancelled':
          return RoutePaths.trips;

        case 'wallet':
        case 'wallet_credit':
        case 'wallet_refund':
          return RoutePaths.wallet;

        case 'topup':
        case 'topup_approved':
        case 'topup_rejected':
        case 'add_points':
          return RoutePaths.wallet;

        case 'tracking':
        case 'live_map':
        case 'live_tracking':
        case 'bus_approaching':
        case 'approaching':
        case 'bus_arrived_at_boarding_stop':
        case 'bus_arrived':
        case 'trip_update':
        case 'trip_delayed':
        case 'next_stop_update':
        case 'next_stop':
          if (tripId != null && tripId.isNotEmpty) {
            return '/trips/$tripId/tracking';
          }
          return RoutePaths.liveBusMap;

        default:
          // Fallback based on specific ID presence
          if (tripId != null && tripId.isNotEmpty) {
            return '/trips/$tripId/tracking';
          }
          return RoutePaths.notifications;
      }
    } catch (e) {
      debugPrint('[NotificationRouter] Error parsing route payload: $e');
      return RoutePaths.notifications;
    }
  }

  static bool _isBookingQrRoute(String? value) {
    if (value == null || value.isEmpty) return false;
    final normalized = value.replaceAll(RegExp(r'/+'), '/');
    return RegExp(r'^/bookings?/[^/]+/qr$').hasMatch(normalized);
  }

  static bool _isBookingLifecyclePayload(String? value) {
    if (value == null || value.isEmpty) return false;
    return value == 'ticket' ||
        value == 'booking' ||
        value == 'booking_qr' ||
        value == 'booking_confirmed' ||
        value == 'booking_cancelled' ||
        value == 'booking_refunded' ||
        value == 'booking_refund' ||
        value == 'refund_booking' ||
        value == 'seat_changed' ||
        value == 'extra_seat_confirmed' ||
        value == 'extra_seat_cancelled';
  }

  static bool _isBookingRefundPayload(String? value, {String? bookingId}) {
    if (value == null || value.isEmpty) return false;
    if (bookingId == null || bookingId.isEmpty) return false;
    return value == 'refund' ||
        value == 'refunded' ||
        value == 'wallet_refund' ||
        value == 'points_refunded';
  }

  /// Navigates safely using root navigator context / GoRouter.
  static void navigateToDestination(Map<String, dynamic>? data) {
    final route = resolveRoute(data);
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      GoRouter.of(context).push(route);
    } else {
      debugPrint(
        '[NotificationRouter] Root navigator context not ready for route: $route',
      );
    }
  }
}
