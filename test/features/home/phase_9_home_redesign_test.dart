import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/features/home/domain/entities/announcement.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_cubit.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_state.dart';
import 'package:amomy_bus/features/home/presentation/pages/passenger_home_page.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_activity_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_announcements_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_upcoming_trip_card.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTrackingRepository implements TrackingRepository {
  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async =>
      const TrackingSummary(
        status: LiveTrackingStatus.offline,
        routeStops: [],
        isInServiceWindow: false,
        serviceWindow: 'closed',
        cairoTime: '12:00:00',
        cairoDate: '2026-09-16',
        activeDirection: TrackingDirection.outbound,
      );

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

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<TrackingRepository>()) {
      getIt.registerSingleton<TrackingRepository>(_MockTrackingRepository());
    }
  });

  Widget buildApp(Widget child, {Locale locale = const Locale('en')}) {
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
      home: child,
    );
  }

  final trip = PassengerUpcomingTrip(
    bookingId: 'booking-1',
    tripId: 'trip-1',
    direction: 'outbound',
    originNameAr: 'ميت فضالة',
    originNameEn: 'Mit Fadala',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    serviceDate: DateTime(2026, 9, 16),
    departureAt: DateTime.utc(2026, 9, 16, 10),
    departureTime: '13:00',
    seatNumber: 'B4',
    farePoints: 30,
    bookingStatus: 'confirmed',
    qrToken: 'qr-token-1',
  );

  HomeSummary summary({PassengerUpcomingTrip? upcomingTrip}) => HomeSummary(
    profile: const PassengerProfileSummary(fullName: 'Ahmed', avatarUrl: null),
    availablePoints: 2000,
    upcomingTrip: upcomingTrip,
    activity: const PassengerActivityMetrics(
      tripsThisMonth: 4,
      completedTrips: 12,
      pointsSpentThisMonth: 120,
      missedTrips: 0,
    ),
  );

  group('Final approved Home layout', () {
    testWidgets('keeps Book Now, tracking, trip, then activity in order', (
      tester,
    ) async {
      final cubit = HomeCubit.idle(
        initialState: HomeState(
          status: HomeStatus.loaded,
          summary: summary(upcomingTrip: trip),
          announcements: const [
            Announcement(
              id: 'hidden-announcement',
              titleAr: 'تنبيه',
              titleEn: 'Alert',
              descriptionAr: 'وصف',
              descriptionEn: 'Description',
              type: 'announcement',
              sortOrder: 1,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildApp(PassengerHomePage(homeCubit: cubit)));
      await tester.pumpAndSettle();

      final book = find.byType(HomeBookRideCard);
      final tracking = find.byType(HomeLiveTrackingCard);
      final upcoming = find.byType(HomeUpcomingTripCard);
      final activity = find.byType(HomeActivitySection);
      expect(book, findsOneWidget);
      expect(tracking, findsOneWidget);
      expect(upcoming, findsOneWidget);
      expect(activity, findsOneWidget);
      expect(find.byType(HomeAnnouncementsSection), findsNothing);
      expect(
        tester.getTopLeft(book).dy,
        lessThan(tester.getTopLeft(tracking).dy),
      );
      expect(
        tester.getTopLeft(tracking).dy,
        lessThan(tester.getTopLeft(upcoming).dy),
      );
      expect(
        tester.getTopLeft(upcoming).dy,
        lessThan(tester.getTopLeft(activity).dy),
      );
    });

    testWidgets('uses Cairo time and only QR and cancel for a booking', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(Scaffold(body: HomeUpcomingTripCard(upcomingTrip: trip))),
      );
      await tester.pumpAndSettle();

      expect(find.text('1:00 PM'), findsOneWidget);
      expect(find.text('QR'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.textContaining('Mit Fadala'), findsNothing);
      expect(find.textContaining('Mansoura'), findsNothing);
      expect(find.textContaining('Change Seat'), findsNothing);
      expect(find.textContaining('Live Map'), findsNothing);
    });

    testWidgets(
      'shows a compact empty state and only offers Book Now when allowed',
      (tester) async {
        await tester.pumpWidget(
          buildApp(
            const Scaffold(
              body: HomeUpcomingTripCard(
                isBookingAvailable: false,
                hasLoadedAvailability: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No upcoming trips'), findsOneWidget);
        expect(find.text('Book Now'), findsNothing);

        await tester.pumpWidget(
          buildApp(const Scaffold(body: HomeUpcomingTripCard())),
        );
        await tester.pumpAndSettle();
        expect(find.text('Book Now'), findsOneWidget);
      },
    );

    testWidgets('keeps the primary empty CTA and donut safe at 320px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const HomeUpcomingTripCard(),
                  const SizedBox(height: 24),
                  HomeActivitySection(activity: summary().activity),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bookButton = find.byKey(const Key('home-upcoming-book-now'));
      expect(bookButton, findsOneWidget);
      expect(tester.getSize(bookButton).width, greaterThanOrEqualTo(148));
      expect(find.text('Book Now'), findsOneWidget);
      expect(
        find.byKey(const Key('home-activity-completion-ring')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('localizes compact trip and activity content in Arabic', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HomeUpcomingTripCard(upcomingTrip: trip),
                  HomeActivitySection(activity: summary().activity),
                ],
              ),
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1:00 م'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('نشاطك'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
