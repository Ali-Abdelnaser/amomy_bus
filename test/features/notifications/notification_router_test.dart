import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:amomy_bus/app/router/app_router.dart';
import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_event_catalog.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

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

    test('routes simulator APNs payload using root AMOMY data fields', () {
      expect(
        NotificationRouter.resolveRoute({
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
          'trip_id': 'trip-simulator',
          'route': 'live_tracking',
        }),
        '/trips/trip-simulator/tracking',
      );
    });

    test('routes booking lifecycle notifications to My Trips', () {
      expect(
        NotificationRouter.resolveRoute({
          'screen': 'ticket',
          'booking_id': 'b-123',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'booking_confirmed',
          'bookingId': 'b-456',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'booking_cancelled',
          'booking_id': 'b-456',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'booking_refunded',
          'booking_id': 'b-456',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'seat_changed',
          'booking_id': 'b-789',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'extra_seat_confirmed',
          'booking_id': 'b-789',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'extra_seat_cancelled',
          'booking_id': 'b-789',
        }),
        RoutePaths.trips,
      );
    });

    test('routes booking notifications without IDs to My Trips', () {
      expect(
        NotificationRouter.resolveRoute({'screen': 'ticket'}),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'booking_cancelled'}),
        RoutePaths.trips,
      );
    });

    test('routes old booking QR notification payloads to My Trips', () {
      expect(
        NotificationRouter.resolveRoute({
          'route': '/booking/b-123/qr',
          'booking_id': 'b-123',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'destination': '/bookings/b-456/qr',
          'booking_id': 'b-456',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'screen': 'booking_qr',
          'booking_id': 'b-789',
        }),
        RoutePaths.trips,
      );
    });

    test('routes booking refund payloads to My Trips', () {
      expect(
        NotificationRouter.resolveRoute({
          'type': 'wallet_refund',
          'booking_id': 'b-123',
        }),
        RoutePaths.trips,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'refund',
          'booking_id': 'b-789',
        }),
        RoutePaths.trips,
      );
    });

    test(
      'routes wallet, topup, refund, and credit destinations to /wallet',
      () {
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
          NotificationRouter.resolveRoute({'type': 'points_adjusted'}),
          RoutePaths.wallet,
        );
        expect(
          NotificationRouter.resolveRoute({'screen': 'add_points'}),
          RoutePaths.wallet,
        );
      },
    );

    test(
      'routes live tracking / approaching / arrived / trip update destinations with tripId',
      () {
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
      },
    );

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
        NotificationRouter.resolveRoute({
          'type': 'bus_arrived_at_boarding_stop',
        }),
        RoutePaths.liveBusMap,
      );
    });

    test(
      'every catalog sample payload resolves to a valid application route',
      () {
        for (final event in NotificationEventCatalog.allEvents) {
          final route = NotificationRouter.resolveRoute(event.samplePayload);
          expect(
            route.startsWith('/'),
            isTrue,
            reason:
                '${event.eventType} payload resolved to invalid route: $route',
          );
        }
      },
    );

    test('falls back safely on unknown or unexpected keys', () {
      expect(
        NotificationRouter.resolveRoute({'random_key': 12345}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({'type': 'totally_unknown'}),
        RoutePaths.notifications,
      );
      expect(
        NotificationRouter.resolveRoute({
          'type': 'unknown_bookingish_event',
          'booking_id': 'b-unknown',
        }),
        RoutePaths.notifications,
      );
    });
  });

  group('NotificationRouter Post-Booking Tap Crash Regression (Tests A - G)', () {
    setUp(() {
      NotificationRouter.resetDeduplication();
    });

    Widget createTestApp({
      required GoRouter router,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp.router(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        routerConfig: router,
      );
    }

    GoRouter buildTestRouter({String initialLocation = RoutePaths.home}) {
      return GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: initialLocation,
        routes: [
          StatefulShellRoute.indexedStack(
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state, navigationShell) =>
                Scaffold(body: navigationShell),
            branches: [
              StatefulShellBranch(
                navigatorKey: shellHomeNavigatorKey,
                routes: [
                  GoRoute(
                    path: RoutePaths.home,
                    builder: (context, state) => const Text('Home Screen'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: shellTripsNavigatorKey,
                routes: [
                  GoRoute(
                    path: RoutePaths.trips,
                    builder: (context, state) => const Text('Trips Screen'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: shellWalletNavigatorKey,
                routes: [
                  GoRoute(
                    path: RoutePaths.wallet,
                    builder: (context, state) => const Text('Wallet Screen'),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: RoutePaths.bookTrip,
            builder: (context, state) => const Text('Book Trip Screen'),
          ),
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: RoutePaths.notifications,
            builder: (context, state) => const Text('Notifications Screen'),
          ),
        ],
      );
    }

    testWidgets(
      'Test A: Booking confirmed notification tap opens /trips with no assertion',
      (tester) async {
        final router = buildTestRouter();
        await tester.pumpWidget(createTestApp(router: router));
        await tester.pumpAndSettle();

        // Navigate imperatively to /book-trip (over the shell, just like the real app)
        router.push(RoutePaths.bookTrip);
        await tester.pumpAndSettle();
        expect(find.text('Book Trip Screen'), findsOneWidget);

        // Tap notification
        NotificationRouter.navigateToDestination({
          'type': 'booking_confirmed',
          'notification_id': 'notif-test-a',
          'booking_id': 'b-123',
        });
        await tester.pumpAndSettle();

        // Must navigate to Trips Screen cleanly with zero assertion errors
        expect(find.text('Trips Screen'), findsOneWidget);
        expect(find.text('Book Trip Screen'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test B: Already on /trips -> tap notification remains safe, no duplicate stack',
      (tester) async {
        final router = buildTestRouter(initialLocation: RoutePaths.trips);
        await tester.pumpWidget(createTestApp(router: router));
        await tester.pumpAndSettle();
        expect(find.text('Trips Screen'), findsOneWidget);

        // Tap notification resolving to /trips
        NotificationRouter.navigateToDestination({
          'type': 'booking_confirmed',
          'notification_id': 'notif-test-b',
        });
        await tester.pumpAndSettle();

        // Stays safely on Trips Screen with no duplicate keys or assertion errors
        expect(find.text('Trips Screen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test C: Tap notification immediately after booking success -> only one valid final navigation',
      (tester) async {
        final router = buildTestRouter();
        await tester.pumpWidget(createTestApp(router: router));
        await tester.pumpAndSettle();

        router.push(RoutePaths.bookTrip);
        await tester.pumpAndSettle();
        expect(find.text('Book Trip Screen'), findsOneWidget);

        // Rapid double-tap or tap immediately after booking success
        NotificationRouter.navigateToDestination({
          'type': 'booking_confirmed',
          'notification_id': 'notif-test-c',
        });
        NotificationRouter.navigateToDestination({
          'type': 'booking_confirmed',
          'notification_id': 'notif-test-c',
        });
        await tester.pumpAndSettle();

        expect(find.text('Trips Screen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test D: Same notification callback delivered twice -> deduplicated, single navigation',
      (tester) async {
        final router = buildTestRouter();
        await tester.pumpWidget(createTestApp(router: router));
        await tester.pumpAndSettle();

        router.push(RoutePaths.bookTrip);
        await tester.pumpAndSettle();

        // First delivery
        NotificationRouter.navigateToDestination({
          'notification_id': 'duplicate-msg-id-123',
          'type': 'booking_confirmed',
        });
        await tester.pumpAndSettle();
        expect(find.text('Trips Screen'), findsOneWidget);

        // Second delivery of same notification ID
        NotificationRouter.navigateToDestination({
          'notification_id': 'duplicate-msg-id-123',
          'type': 'booking_confirmed',
        });
        await tester.pumpAndSettle();

        expect(find.text('Trips Screen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Test E: Different notification later -> navigation succeeds', (
      tester,
    ) async {
      final router = buildTestRouter();
      await tester.pumpWidget(createTestApp(router: router));
      await tester.pumpAndSettle();

      // First notification -> /trips
      NotificationRouter.navigateToDestination({
        'notification_id': 'first-notif',
        'type': 'booking_confirmed',
      });
      await tester.pumpAndSettle();
      expect(find.text('Trips Screen'), findsOneWidget);

      // Second different notification later -> /wallet
      NotificationRouter.navigateToDestination({
        'notification_id': 'second-notif',
        'type': 'wallet_credit',
      });
      await tester.pumpAndSettle();
      expect(find.text('Wallet Screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Test F: Cold-start / background notification routing contract intact',
      (tester) async {
        // 1. Contract check: resolveRoute routes cold start / background payloads correctly
        expect(
          NotificationRouter.resolveRoute({
            'screen': 'ticket',
            'booking_id': 'b-cold',
          }),
          RoutePaths.trips,
        );
        expect(
          NotificationRouter.resolveRoute({'screen': 'wallet'}),
          RoutePaths.wallet,
        );

        // 2. Pending dispatch before root context is mounted
        NotificationRouter.navigateToDestination({
          'notification_id': 'cold-start-id',
          'type': 'booking_confirmed',
        });

        final router = buildTestRouter();
        await tester.pumpWidget(createTestApp(router: router));
        await tester.pumpAndSettle();

        // Should have processed the pending payload once mounted
        expect(find.text('Trips Screen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test G: Booking confirmation without tapping notification -> BookingSuccessView preserved',
      (tester) async {
        final sampleBooking = PassengerBooking(
          bookingId: 'booking-g-1',
          tripId: 'trip-g-1',
          direction: BookingDirection.outbound,
          originNameAr: 'ميت فضالة',
          originNameEn: 'Mit Fadala',
          destinationNameAr: 'بوابة توشكى',
          destinationNameEn: 'Toshka Gate',
          serviceDate: DateTime(2026, 9, 16),
          departureTime: '08:00 AM',
          departureAt: DateTime(2026, 9, 16, 8, 0),
          seatNumber: '04',
          farePoints: 30.0,
          status: 'confirmed',
          qrToken: 'sample-qr-token-123',
          bookedAt: DateTime(2026, 9, 16, 7, 50),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: Scaffold(body: BookingSuccessView(booking: sampleBooking)),
          ),
        );
        await tester.pumpAndSettle();

        // BookingSuccessView is displayed and preserved intact
        expect(find.byType(BookingSuccessView), findsOneWidget);
        expect(find.text('Booking Confirmed!'), findsOneWidget);
        expect(find.text('SEAT'), findsOneWidget);
        expect(find.text('04'), findsOneWidget);
        expect(find.text('My Trips'), findsOneWidget);
        expect(find.text('Go to Home'), findsOneWidget);
      },
    );
  });
}
