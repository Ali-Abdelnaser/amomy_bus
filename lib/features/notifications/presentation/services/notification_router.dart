import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_paths.dart';

class NotificationRouter {
  NotificationRouter._();

  /// Resolves the destination route path from a notification data payload.
  /// Falls back safely to '/notifications' or '/home' on unknown or malformed payloads.
  static String resolveRoute(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return RoutePaths.notifications;
    }

    try {
      final screen = (data['screen'] ?? data['destination'] ?? data['type'])
          ?.toString()
          .toLowerCase()
          .trim();

      final bookingId = (data['booking_id'] ?? data['bookingId'])?.toString().trim();
      final tripId = (data['trip_id'] ?? data['tripId'])?.toString().trim();

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
          if (bookingId != null && bookingId.isNotEmpty) {
            return '/bookings/$bookingId/qr';
          }
          return RoutePaths.trips;

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
          if (bookingId != null && bookingId.isNotEmpty) {
            return '/bookings/$bookingId/qr';
          }
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

  /// Navigates safely using root navigator context / GoRouter.
  static void navigateToDestination(Map<String, dynamic>? data) {
    final route = resolveRoute(data);
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      GoRouter.of(context).push(route);
    } else {
      debugPrint('[NotificationRouter] Root navigator context not ready for route: $route');
    }
  }
}
