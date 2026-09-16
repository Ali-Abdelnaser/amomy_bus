import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_paths.dart';
import 'notification_payload_parser.dart';

class NotificationRouter {
  NotificationRouter._();

  static const Set<String> _shellRoutes = {
    RoutePaths.home,
    RoutePaths.trips,
    RoutePaths.wallet,
    RoutePaths.profile,
  };

  /// Returns true if the given route path corresponds to a StatefulShellRoute branch tab.
  static bool isShellRoute(String path) => _shellRoutes.contains(path);

  // Bounded deduplication cache to prevent handling the exact same notification tap twice
  static final Set<String> _processedNotificationIds = <String>{};
  static final List<String> _processedNotificationIdOrder = <String>[];
  static const int _maxDedupeCacheSize = 100;

  static DateTime? _lastNavigatedTime;
  static String? _lastNavigatedRoute;
  static Map<String, dynamic>? _pendingPayload;

  @visibleForTesting
  static void resetDeduplication() {
    _processedNotificationIds.clear();
    _processedNotificationIdOrder.clear();
    _lastNavigatedTime = null;
    _lastNavigatedRoute = null;
    _pendingPayload = null;
  }

  static String? _extractNotificationId(Map<String, dynamic>? data) {
    if (data == null) return null;
    final id = data['notification_id'] ??
        data['id'] ??
        data['event_id'] ??
        data['message_id'] ??
        data['dedupe_key'];
    if (id != null && id.toString().trim().isNotEmpty) {
      return id.toString().trim();
    }
    return null;
  }

  static void _rememberNotificationId(String id) {
    if (_processedNotificationIds.contains(id)) return;
    _processedNotificationIds.add(id);
    _processedNotificationIdOrder.add(id);
    while (_processedNotificationIdOrder.length > _maxDedupeCacheSize) {
      final oldest = _processedNotificationIdOrder.removeAt(0);
      _processedNotificationIds.remove(oldest);
    }
  }

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
  /// Enforces idempotency, deduplication, and shell branch switching.
  static void navigateToDestination(Map<String, dynamic>? data) {
    final route = resolveRoute(data);
    final notifId = _extractNotificationId(data);
    final now = DateTime.now();

    // 1. Deduplication by explicit notification ID (bounded LRU)
    if (notifId != null && _processedNotificationIds.contains(notifId)) {
      debugPrint(
        '[NotificationRouter] Skipping duplicate notification tap for ID: $notifId',
      );
      return;
    }

    // 2. Tap throttling (debounce rapid repeated taps for the same route within 800ms)
    if (_lastNavigatedTime != null &&
        _lastNavigatedRoute == route &&
        now.difference(_lastNavigatedTime!) < const Duration(milliseconds: 800)) {
      debugPrint(
        '[NotificationRouter] Debouncing rapid notification tap for route: $route',
      );
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      debugPrint(
        '[NotificationRouter] Root navigator context not ready for route: $route. Stashing pending payload.',
      );
      _pendingPayload = data;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pendingPayload != null) {
          final pending = _pendingPayload;
          _pendingPayload = null;
          navigateToDestination(pending);
        }
      });
      return;
    }

    // 3. Idempotency: do not navigate if router is already at the target route
    try {
      final router = GoRouter.of(context);
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath == route) {
        debugPrint(
          '[NotificationRouter] Already at target destination: $route. Skipping navigation.',
        );
        if (notifId != null) _rememberNotificationId(notifId);
        _lastNavigatedTime = now;
        _lastNavigatedRoute = route;
        return;
      }

      // 4. Perform safe navigation
      if (isShellRoute(route)) {
        // Shell routes MUST use go() to switch branches cleanly, clearing any modal overlay without duplicate key assertion
        router.go(route);
      } else {
        // Non-shell routes are full-screen pages on root navigator
        router.push(route);
      }

      if (notifId != null) _rememberNotificationId(notifId);
      _lastNavigatedTime = now;
      _lastNavigatedRoute = route;
    } catch (e, st) {
      debugPrint('[NotificationRouter] Navigation error for route $route: $e\n$st');
    }
  }
}
