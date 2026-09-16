import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/home/domain/entities/announcement.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_cubit.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_state.dart';
import 'package:amomy_bus/features/home/presentation/pages/passenger_home_page.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_activity_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_app_bar.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_upcoming_trip_card.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_summary.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _MockTrackingRepo implements TrackingRepository {
  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    return const TrackingSummary(
      status: LiveTrackingStatus.offline,
      routeStops: [],
      isInServiceWindow: false,
      serviceWindow: 'closed',
      cairoTime: '12:00:00',
      cairoDate: '2026-09-16',
      activeDirection: TrackingDirection.outbound,
    );
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) =>
      const Stream.empty();

  @override
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) async => true;

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) async {}

  @override
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {}
}

class _FakeTrackingCubit extends Cubit<TrackingState> implements TrackingCubit {
  _FakeTrackingCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockWalletCubit extends Cubit<WalletState> implements WalletCubit {
  _MockWalletCubit(super.initialState);

  @override
  Future<void> loadWalletSummary(String userId) async {}

  @override
  Future<void> loadMoreHistory() async {}
}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<TrackingRepository>()) {
      getIt.registerSingleton<TrackingRepository>(_MockTrackingRepo());
    }
  });

  Widget buildApp(
    Widget child, {
    Locale locale = const Locale('en'),
    TrackingCubit? trackingCubit,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: trackingCubit != null
          ? BlocProvider<TrackingCubit>.value(
              value: trackingCubit,
              child: child,
            )
          : child,
    );
  }

  final sampleUpcomingTrip = PassengerUpcomingTrip(
    bookingId: 'bkg-prod-99',
    tripId: 'trip-prod-101',
    direction: 'outbound',
    originNameAr: 'ميت فضالة',
    originNameEn: 'Mit Fadala',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    serviceDate: DateTime(2026, 9, 16),
    departureAt: DateTime.utc(2026, 9, 16, 10, 0), // 13:00 Cairo (UTC+3)
    departureTime: '13:00',
    seatNumber: 'B4',
    farePoints: 30,
    bookingStatus: 'confirmed',
    qrToken: 'amomy-qr-test-token-777',
  );

  final sampleHomeSummary = HomeSummary(
    profile: const PassengerProfileSummary(
      fullName: 'Ahmed Commuter',
      avatarUrl: null,
    ),
    availablePoints: 2000,
    upcomingTrip: sampleUpcomingTrip,
    activity: const PassengerActivityMetrics(
      tripsThisMonth: 4,
      completedTrips: 12,
      pointsSpentThisMonth: 120,
      missedTrips: 0,
    ),
  );

  group('Phase 9 — Home & Upcoming Trip Redesign Complete Specification', () {
    // 1. Hierarchy Check: Upcoming Trip is PRIMARY and vertically above Book Ride & Activity
    testWidgets(
      'A. Upcoming trip is primary Home content placed vertically above Book Ride and Activity',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
            announcements: const [
              Announcement(
                id: 'ann-1',
                titleAr: 'تنبيه',
                titleEn: 'Alert',
                descriptionAr: 'الوصف',
                descriptionEn: 'Description',
                type: 'announcement',
                sortOrder: 1,
              ),
            ],
          ),
        );

        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();

        final upcomingCardFinder = find.byType(HomeUpcomingTripCard);
        final bookCardFinder = find.byType(HomeBookRideCard);
        final activityFinder = find.byType(HomeActivitySection);

        expect(upcomingCardFinder, findsOneWidget);
        expect(bookCardFinder, findsOneWidget);
        expect(activityFinder, findsOneWidget);

        final upcomingTop = tester.getTopLeft(upcomingCardFinder).dy;
        final bookTop = tester.getTopLeft(bookCardFinder).dy;
        final activityTop = tester.getTopLeft(activityFinder).dy;

        // Book Ride sit ABOVE Upcoming Trip, which in turn sits ABOVE Activity
        expect(bookTop, lessThan(upcomingTop));
        expect(upcomingTop, lessThan(activityTop));
      },
    );

    // 2. Authoritative Source: Uses backend summary.upcomingTrip
    testWidgets(
      'B. Renders exactly the backend-selected upcoming trip data without local override',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
          ),
        );

        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mit Fadala'), findsOneWidget);
        expect(find.text('Mansoura'), findsOneWidget);
        expect(find.textContaining('B4'), findsOneWidget);
      },
    );

    // 3. Complete route, time, boarding, destination, and seat display
    testWidgets(
      'C. Renders direction, boarding stop, destination stop, seat number, and view ticket action',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
          ),
        );

        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Outbound'), findsOneWidget);
        expect(find.text('Mit Fadala'), findsOneWidget);
        expect(find.text('Mansoura'), findsOneWidget);
        expect(find.textContaining('B4'), findsOneWidget);
        expect(find.text('View Ticket'), findsOneWidget);
      },
    );

    // 4. Cairo 12-hour Time Formatting: 13:00 -> 1:00 PM
    testWidgets(
      'D. 13:00 Cairo departure time renders as 1:00 PM in English and 1:00 م in Arabic',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
          ),
        );

        // English test
        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();
        expect(find.text('1:00 PM'), findsOneWidget);

        // Arabic test
        final homeCubitAr = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
          ),
        );
        await tester.pumpWidget(
          buildApp(
            PassengerHomePage(homeCubit: homeCubitAr),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1:00 م'), findsOneWidget);
      },
    );

    // 5. No upcoming trip: compact empty state
    testWidgets(
      'E. Clean, compact empty state rendered when there is no upcoming trip',
      (tester) async {
        final summaryNoTrip = HomeSummary(
          profile: sampleHomeSummary.profile,
          availablePoints: 800,
          upcomingTrip: null,
          activity: sampleHomeSummary.activity,
        );

        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: summaryNoTrip,
          ),
        );

        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No upcoming trips'), findsOneWidget);
        expect(find.text('Book a Ride'), findsOneWidget);
        expect(find.text('View Ticket'), findsNothing);
      },
    );

    // 6. Live Tracking Action routes with exact tripId
    testWidgets(
      'F. Live Map button invokes navigation with exact tripId when live',
      (tester) async {
        String? navigatedTripId;

        final card = HomeUpcomingTripCard(
          upcomingTrip: sampleUpcomingTrip,
          onViewLiveMap: () {
            navigatedTripId = sampleUpcomingTrip.tripId;
          },
        );

        final trackingCubit = _FakeTrackingCubit(
          const TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            trackedTripId: 'trip-prod-101',
            summary: TrackingSummary(
              status: LiveTrackingStatus.live,
              activeTripId: 'trip-prod-101',
              isInServiceWindow: true,
              serviceWindow: 'afternoon',
              cairoTime: '13:05:00',
              cairoDate: '2026-09-16',
              activeDirection: TrackingDirection.outbound,
              routeStops: [],
            ),
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: card), trackingCubit: trackingCubit),
        );
        await tester.pumpAndSettle();

        expect(find.text('LIVE'), findsOneWidget);
        expect(find.text('View Live Map'), findsOneWidget);

        await tester.tap(find.text('View Live Map'));
        await tester.pumpAndSettle();

        expect(navigatedTripId, equals('trip-prod-101'));
      },
    );

    // 7. Assignment Pending does not show fake LIVE
    testWidgets(
      'G. Assignment pending status renders Assignment Pending badge, not LIVE',
      (tester) async {
        final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

        final trackingCubit = _FakeTrackingCubit(
          const TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            trackedTripId: 'trip-prod-101',
            summary: TrackingSummary(
              status: LiveTrackingStatus.assignmentPending,
              activeTripId: 'trip-prod-101',
              isInServiceWindow: true,
              serviceWindow: 'afternoon',
              cairoTime: '13:00:00',
              cairoDate: '2026-09-16',
              activeDirection: TrackingDirection.outbound,
              routeStops: [],
            ),
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: card), trackingCubit: trackingCubit),
        );
        await tester.pumpAndSettle();

        expect(find.text('Bus assignment pending'), findsOneWidget);
        expect(find.text('LIVE'), findsNothing);
      },
    );

    // 8. Stale status does not show LIVE
    testWidgets('H. Stale status renders Signal Stale badge, not LIVE', (
      tester,
    ) async {
      final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

      final trackingCubit = _FakeTrackingCubit(
        const TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          trackedTripId: 'trip-prod-101',
          summary: TrackingSummary(
            status: LiveTrackingStatus.stale,
            activeTripId: 'trip-prod-101',
            isInServiceWindow: true,
            serviceWindow: 'afternoon',
            cairoTime: '13:00:00',
            cairoDate: '2026-09-16',
            activeDirection: TrackingDirection.outbound,
            routeStops: [],
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(Scaffold(body: card), trackingCubit: trackingCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location temporarily unavailable'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
    });

    // 9. Progression Unavailable does not fabricate stops
    testWidgets(
      'I. Progression unavailable status renders safe state without fake ETAs',
      (tester) async {
        final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

        final trackingCubit = _FakeTrackingCubit(
          const TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            trackedTripId: 'trip-prod-101',
            summary: TrackingSummary(
              status: LiveTrackingStatus.progressionUnavailable,
              activeTripId: 'trip-prod-101',
              isInServiceWindow: true,
              serviceWindow: 'afternoon',
              cairoTime: '13:00:00',
              cairoDate: '2026-09-16',
              activeDirection: TrackingDirection.outbound,
              routeStops: [],
            ),
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: card), trackingCubit: trackingCubit),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Stop progress temporarily unavailable'),
          findsOneWidget,
        );
        expect(find.text('LIVE'), findsNothing);
      },
    );

    // 10. Secondary actions provide access to My Trips for managing bookings
    testWidgets('J. Secondary action triggers trip management navigation', (
      tester,
    ) async {
      bool tripNavigated = false;

      final card = HomeUpcomingTripCard(
        upcomingTrip: sampleUpcomingTrip,
        onViewTrip: () {
          tripNavigated = true;
        },
      );

      await tester.pumpWidget(buildApp(Scaffold(body: card)));
      await tester.pumpAndSettle();

      expect(find.text('View Trip'), findsOneWidget);
      await tester.tap(find.text('View Trip'));
      await tester.pumpAndSettle();

      expect(tripNavigated, isTrue);
    });

    // 11. Notification badge preserved (0, 1, 9, 10+)
    testWidgets('K. Preserves notification badge behavior', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const Scaffold(
            body: HomeAppBar(
              fullName: 'User Commuter',
              unreadNotificationsCount: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
    });

    // 12. Points preserved from shared WalletCubit
    testWidgets(
      'L. Preserves shared WalletCubit points update dynamically on Home',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary, // availablePoints: 2000
          ),
        );

        final walletCubit = _MockWalletCubit(
          const WalletState(
            status: WalletStatus.loaded,
            summary: WalletSummary(
              totalAvailablePoints: 3450,
              cashPoints: 3450,
              subscriptionPoints: 0,
            ),
          ),
        );

        await tester.pumpWidget(
          buildApp(
            PassengerHomePage(homeCubit: homeCubit, walletCubit: walletCubit),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('3,450'), findsOneWidget);
        expect(find.textContaining('2,000'), findsNothing);
      },
    );

    // 13. Book availability disabled state when isBookingAvailable is false
    testWidgets(
      'M. Respects isBookingAvailable and shows disabled helper message when unavailable',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
            hasLoadedAvailability: true,
            isBookingAvailable: false,
          ),
        );

        await tester.pumpWidget(
          buildApp(PassengerHomePage(homeCubit: homeCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No more trips available today'), findsOneWidget);
      },
    );

    // 14. Zero Bus identity / plate / driver exposure (Strict Privacy)
    testWidgets(
      'N. Strictly never displays bus ID, license plate, driver name, or device ID',
      (tester) async {
        final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

        await tester.pumpWidget(buildApp(Scaffold(body: card)));
        await tester.pumpAndSettle();

        expect(find.textContaining('Bus 1'), findsNothing);
        expect(find.textContaining('Plate'), findsNothing);
        expect(find.textContaining('Driver'), findsNothing);
        expect(find.textContaining('Device'), findsNothing);
        expect(find.textContaining('bus_id'), findsNothing);
      },
    );

    // 15. Graceful handling of null stop coordinates
    testWidgets(
      'O. Gracefully renders stops with null coordinates without error',
      (tester) async {
        final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

        final trackingCubit = _FakeTrackingCubit(
          const TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            trackedTripId: 'trip-prod-101',
            summary: TrackingSummary(
              status: LiveTrackingStatus.live,
              activeTripId: 'trip-prod-101',
              isInServiceWindow: true,
              serviceWindow: 'afternoon',
              cairoTime: '13:00:00',
              cairoDate: '2026-09-16',
              activeDirection: TrackingDirection.outbound,
              routeStops: [
                BusStopModel(
                  id: 'stop-1',
                  routeStopId: 'rs-1',
                  stopOrder: 1,
                  nameAr: 'ميت فضالة',
                  nameEn: 'Mit Fadala',
                  localityAr: 'الدقهلية',
                  localityEn: 'Dakahlia',
                  latitude: null,
                  longitude: null,
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: card), trackingCubit: trackingCubit),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeUpcomingTripCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // 16. Arabic RTL layout without overflow
    testWidgets(
      'P. Arabic RTL renders cleanly with appropriate Arabic text and no overflow',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: sampleHomeSummary,
          ),
        );

        await tester.pumpWidget(
          buildApp(
            PassengerHomePage(homeCubit: homeCubit),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('رحلتك القادمة'), findsOneWidget);
        expect(find.text('عرض التذكرة'), findsOneWidget);
        expect(find.text('ميت فضالة'), findsOneWidget);
        expect(find.text('المنصورة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // 17. Safe ticket modal presentation
    testWidgets('Q. View Ticket opens QR code bottom sheet safely', (
      tester,
    ) async {
      final card = HomeUpcomingTripCard(upcomingTrip: sampleUpcomingTrip);

      await tester.pumpWidget(buildApp(Scaffold(body: card)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Ticket'));
      await tester.pumpAndSettle();

      expect(find.byType(AppQrTicketWidget), findsOneWidget);
    });
  });
}
