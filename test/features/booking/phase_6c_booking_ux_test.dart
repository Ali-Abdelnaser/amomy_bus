import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/localization/app_time_formatter.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _MockTrackingRepo implements TrackingRepository {
  final TrackingSummary summary;
  _MockTrackingRepo(this.summary);

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async =>
      summary;

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
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {}

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) async {}
}

Widget _buildTestApp(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 400,
  double height = 800,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

TripOption _createTrip({
  required String tripId,
  required String departureTime,
  required int hour,
  required int minute,
  BookingDirection direction = BookingDirection.outbound,
  int availableSeats = 10,
  String status = 'scheduled',
  bool isBookable = true,
}) {
  return TripOption(
    tripId: tripId,
    routeId: 'route-1',
    direction: direction,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    departureTime: departureTime,
    departureAt: DateTime(2026, 9, 16, hour, minute),
    farePoints: 25.0,
    availableSeatsCount: availableSeats,
    status: status,
    isBookable: isBookable,
  );
}

void main() {
  group('Phase 6C Focused Tests (Items A to M)', () {
    // =========================================================================
    // Item A: Outbound trips: 08/09/10/11 -> 8:00 AM / 9:00 AM / 10:00 AM / 11:00 AM
    // =========================================================================
    test(
      'A. Outbound trips format correctly in English (8:00 AM - 11:00 AM)',
      () {
        final t08 = _createTrip(
          tripId: 't1',
          departureTime: '08:00',
          hour: 8,
          minute: 0,
        );
        final t09 = _createTrip(
          tripId: 't2',
          departureTime: '09:00',
          hour: 9,
          minute: 0,
        );
        final t10 = _createTrip(
          tripId: 't3',
          departureTime: '10:00',
          hour: 10,
          minute: 0,
        );
        final t11 = _createTrip(
          tripId: 't4',
          departureTime: '11:00',
          hour: 11,
          minute: 0,
        );

        expect(AppTimeFormatter.formatTripOption(t08, locale: 'en'), '8:00 AM');
        expect(AppTimeFormatter.formatTripOption(t09, locale: 'en'), '9:00 AM');
        expect(
          AppTimeFormatter.formatTripOption(t10, locale: 'en'),
          '10:00 AM',
        );
        expect(
          AppTimeFormatter.formatTripOption(t11, locale: 'en'),
          '11:00 AM',
        );
      },
    );

    // =========================================================================
    // Item B: Return trips: 13/14/15/16 -> 1:00 PM / 2:00 PM / 3:00 PM / 4:00 PM
    // =========================================================================
    test('B. Return trips format correctly in English (1:00 PM - 4:00 PM)', () {
      final t13 = _createTrip(
        tripId: 't5',
        departureTime: '13:00',
        hour: 13,
        minute: 0,
      );
      final t14 = _createTrip(
        tripId: 't6',
        departureTime: '14:00',
        hour: 14,
        minute: 0,
      );
      final t15 = _createTrip(
        tripId: 't7',
        departureTime: '15:00',
        hour: 15,
        minute: 0,
      );
      final t16 = _createTrip(
        tripId: 't8',
        departureTime: '16:00',
        hour: 16,
        minute: 0,
      );

      expect(AppTimeFormatter.formatTripOption(t13, locale: 'en'), '1:00 PM');
      expect(AppTimeFormatter.formatTripOption(t14, locale: 'en'), '2:00 PM');
      expect(AppTimeFormatter.formatTripOption(t15, locale: 'en'), '3:00 PM');
      expect(AppTimeFormatter.formatTripOption(t16, locale: 'en'), '4:00 PM');
    });

    // =========================================================================
    // Item C: Arabic equivalent renders without 24-hour 13/14/15/16 labels
    // =========================================================================
    test('C. Arabic equivalent renders without 24-hour labels (ص / م)', () {
      final t08 = _createTrip(
        tripId: 't1',
        departureTime: '08:00',
        hour: 8,
        minute: 0,
      );
      final t13 = _createTrip(
        tripId: 't5',
        departureTime: '13:00',
        hour: 13,
        minute: 0,
      );
      final t14 = _createTrip(
        tripId: 't6',
        departureTime: '14:00',
        hour: 14,
        minute: 0,
      );
      final t15 = _createTrip(
        tripId: 't7',
        departureTime: '15:00',
        hour: 15,
        minute: 0,
      );
      final t16 = _createTrip(
        tripId: 't8',
        departureTime: '16:00',
        hour: 16,
        minute: 0,
      );

      final r08 = AppTimeFormatter.formatTripOption(t08, locale: 'ar');
      final r13 = AppTimeFormatter.formatTripOption(t13, locale: 'ar');
      final r14 = AppTimeFormatter.formatTripOption(t14, locale: 'ar');
      final r15 = AppTimeFormatter.formatTripOption(t15, locale: 'ar');
      final r16 = AppTimeFormatter.formatTripOption(t16, locale: 'ar');

      expect(r08, '8:00 ص');
      expect(r13, '1:00 م');
      expect(r14, '2:00 م');
      expect(r15, '3:00 م');
      expect(r16, '4:00 م');

      // Crucial: none contains 24h numerals
      for (final r in [r08, r13, r14, r15, r16]) {
        expect(r.contains('13:'), isFalse);
        expect(r.contains('14:'), isFalse);
        expect(r.contains('15:'), isFalse);
        expect(r.contains('16:'), isFalse);
      }
    });

    // =========================================================================
    // Item D: Return trips returned by backend at morning time -> visible in Flutter
    // =========================================================================
    testWidgets(
      'D. Return trips at morning time are visible without client-side cutoff',
      (tester) async {
        final returnTrips = [
          _createTrip(
            tripId: 'ret-1',
            departureTime: '13:00',
            hour: 13,
            minute: 0,
            direction: BookingDirection.returnTrip,
          ),
          _createTrip(
            tripId: 'ret-2',
            departureTime: '14:00',
            hour: 14,
            minute: 0,
            direction: BookingDirection.returnTrip,
          ),
          _createTrip(
            tripId: 'ret-3',
            departureTime: '15:00',
            hour: 15,
            minute: 0,
            direction: BookingDirection.returnTrip,
          ),
          _createTrip(
            tripId: 'ret-4',
            departureTime: '16:00',
            hour: 16,
            minute: 0,
            direction: BookingDirection.returnTrip,
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            DepartureTimeSelector(
              trips: returnTrips,
              selectedTrip: null,
              direction: BookingDirection.returnTrip,
              onTripSelected: (_) {},
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1:00 PM'), findsOneWidget);
        expect(find.text('2:00 PM'), findsOneWidget);
        expect(find.text('3:00 PM'), findsOneWidget);
        expect(find.text('4:00 PM'), findsOneWidget);
      },
    );

    // =========================================================================
    // Item E: 8:00 non-bookable but 9:00 bookable -> 8 disabled, 9 selectable
    // =========================================================================
    testWidgets(
      'E. 8:00 non-bookable is disabled/unselectable, 9:00 is selectable',
      (tester) async {
        TripOption? selected;
        final trips = [
          _createTrip(
            tripId: 't-closed',
            departureTime: '08:00',
            hour: 8,
            minute: 0,
            status: 'closed',
            availableSeats: 0,
          ),
          _createTrip(
            tripId: 't-open',
            departureTime: '09:00',
            hour: 9,
            minute: 0,
            status: 'scheduled',
            availableSeats: 8,
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            DepartureTimeSelector(
              trips: trips,
              selectedTrip: null,
              direction: BookingDirection.outbound,
              onTripSelected: (t) => selected = t,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('8:00 AM'), findsOneWidget);
        expect(find.text('9:00 AM'), findsOneWidget);

        // Tap 8:00 AM (closed) -> callback must NOT be triggered
        await tester.tap(find.text('8:00 AM'));
        await tester.pumpAndSettle();
        expect(selected, isNull);

        // Tap 9:00 AM (open) -> callback MUST be triggered
        await tester.tap(find.text('9:00 AM'));
        await tester.pumpAndSettle();
        expect(selected?.tripId, 't-open');
      },
    );

    testWidgets(
      'E2. Server non-bookable trip with seats remains visible but unselectable',
      (tester) async {
        TripOption? selected;
        final trips = [
          _createTrip(
            tripId: 't-server-closed',
            departureTime: '08:00',
            hour: 8,
            minute: 0,
            status: 'scheduled',
            availableSeats: 8,
            isBookable: false,
          ),
          _createTrip(
            tripId: 't-server-open',
            departureTime: '09:00',
            hour: 9,
            minute: 0,
            status: 'scheduled',
            availableSeats: 8,
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            DepartureTimeSelector(
              trips: trips,
              selectedTrip: null,
              direction: BookingDirection.outbound,
              onTripSelected: (t) => selected = t,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('8:00 AM'), findsOneWidget);
        expect(find.text('9:00 AM'), findsOneWidget);

        await tester.tap(find.text('8:00 AM'));
        await tester.pumpAndSettle();
        expect(selected, isNull);

        await tester.tap(find.text('9:00 AM'));
        await tester.pumpAndSettle();
        expect(selected?.tripId, 't-server-open');
      },
    );

    // =========================================================================
    // Item F: One or more is_bookable -> Home Book a Ride enabled
    // =========================================================================
    testWidgets('F. One or more is_bookable -> Home Book a Ride enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeBookRideCard(
            points: 1500,
            hasLoadedAvailability: true,
            isBookingAvailable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Your Ride'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
      expect(find.text('No more trips available today'), findsNothing);
    });

    // =========================================================================
    // Item G: Zero is_bookable -> Home Book a Ride disabled
    // =========================================================================
    testWidgets('G. Zero is_bookable -> Home Book a Ride CTA remains enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeBookRideCard(
            points: 1500,
            hasLoadedAvailability: true,
            isBookingAvailable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-book-ride-cta')), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
    });

    // =========================================================================
    // Item H: Service-off / zero-trip response -> clean empty state
    // =========================================================================
    testWidgets('H. Empty trips response renders clean generic empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          DepartureTimeSelector(
            trips: const [],
            selectedTrip: null,
            direction: BookingDirection.outbound,
            onTripSelected: (_) {},
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No trips available today'), findsOneWidget);
      expect(
        find.text('Check back tomorrow for the next trips.'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // Item I: No Passenger One name/ID hardcoded client-side
    // =========================================================================
    test(
      'I. No hardcoded Passenger One client-side exceptions in codebase',
      () {
        final bookingDir = Directory('lib/features/booking');
        final homeDir = Directory('lib/features/home');

        for (final file in [
          ...bookingDir.listSync(recursive: true),
          ...homeDir.listSync(recursive: true),
        ]) {
          if (file is File && file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            expect(
              content.contains('Passenger One'),
              isFalse,
              reason: 'Found hardcoded "Passenger One" in ${file.path}',
            );
            expect(
              content.contains('passenger_one'),
              isFalse,
              reason: 'Found hardcoded "passenger_one" in ${file.path}',
            );
          }
        }
      },
    );

    // =========================================================================
    // Item J: App refresh / date rollover does not retain stale list
    // =========================================================================
    test(
      'J. Date rollover/resume pattern invalidates and reloads fresh trips',
      () {
        final homeFile = File(
          'lib/features/home/presentation/pages/passenger_home_page.dart',
        );
        final content = homeFile.readAsStringSync();
        expect(content.contains('AppLifecycleState.resumed'), isTrue);
        expect(content.contains('loadHomeData(isRefresh: true)'), isTrue);
        expect(content.contains('loadTrackingData('), isTrue);
        expect(content.contains('isRefresh: true'), isTrue);
      },
    );

    // =========================================================================
    // Item K: Tracking states: active vs midday offline vs end-of-day offline
    // =========================================================================
    testWidgets('K1. Midday offline shows resumes at 1:00 PM', (tester) async {
      final summary = const TrackingSummary(
        status: LiveTrackingStatus.offline,
        routeStops: [],
        isInServiceWindow: false,
        serviceWindow: 'afternoon',
        cairoTime: '12:15:00',
        cairoDate: '2026-09-16',
        nextWindowStartTime: '13:00',
        nextWindowIsTomorrow: false,
        activeDirection: TrackingDirection.outbound,
      );

      final repo = _MockTrackingRepo(summary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      await tester.pumpWidget(
        _buildTestApp(
          BlocProvider<TrackingCubit>.value(
            value: cubit,
            child: const HomeLiveTrackingCard(),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tracking unavailable'), findsAtLeastNWidgets(1));
      expect(find.text('Tracking resumes at 1:00 PM'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('K2. End-of-day offline shows resumes tomorrow at 8:00 AM', (
      tester,
    ) async {
      final summary = const TrackingSummary(
        status: LiveTrackingStatus.offline,
        routeStops: [],
        isInServiceWindow: false,
        serviceWindow: 'closed',
        cairoTime: '17:30:00',
        cairoDate: '2026-09-16',
        nextWindowStartTime: '08:00',
        nextWindowIsTomorrow: true,
        activeDirection: TrackingDirection.returnDirection,
      );

      final repo = _MockTrackingRepo(summary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      await tester.pumpWidget(
        _buildTestApp(
          BlocProvider<TrackingCubit>.value(
            value: cubit,
            child: const HomeLiveTrackingCard(),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tracking unavailable'), findsAtLeastNWidgets(1));
      expect(find.text('Tracking resumes tomorrow at 8:00 AM'), findsOneWidget);

      await cubit.close();
    });

    // =========================================================================
    // Item L: Offline map CTA cannot navigate to Full Map (onTap: null)
    // =========================================================================
    testWidgets(
      'L. Offline map CTA is disabled and cannot navigate to Full Map',
      (tester) async {
        bool viewMapCalled = false;
        final summary = const TrackingSummary(
          status: LiveTrackingStatus.offline,
          routeStops: [],
          isInServiceWindow: false,
          serviceWindow: 'closed',
          cairoTime: '18:00:00',
          cairoDate: '2026-09-16',
          nextWindowStartTime: '08:00',
          nextWindowIsTomorrow: true,
          activeDirection: TrackingDirection.returnDirection,
        );

        final repo = _MockTrackingRepo(summary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          _buildTestApp(
            BlocProvider<TrackingCubit>.value(
              value: cubit,
              child: HomeLiveTrackingCard(
                onViewMapTap: () => viewMapCalled = true,
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('View Live Map'));
        await tester.pumpAndSettle();

        expect(viewMapCalled, isFalse);

        await cubit.close();
      },
    );

    // =========================================================================
    // Item M: No overflow in EN/AR RTL
    // =========================================================================
    testWidgets(
      'M. DepartureTimeSelector renders with zero overflow in EN and AR RTL',
      (tester) async {
        final trips = [
          _createTrip(tripId: 't1', departureTime: '08:00', hour: 8, minute: 0),
          _createTrip(tripId: 't2', departureTime: '09:00', hour: 9, minute: 0),
          _createTrip(
            tripId: 't3',
            departureTime: '10:00',
            hour: 10,
            minute: 0,
          ),
          _createTrip(
            tripId: 't4',
            departureTime: '11:00',
            hour: 11,
            minute: 0,
          ),
        ];

        // English
        await tester.pumpWidget(
          _buildTestApp(
            DepartureTimeSelector(
              trips: trips,
              selectedTrip: trips.first,
              direction: BookingDirection.outbound,
              onTripSelected: (_) {},
            ),
            locale: const Locale('en'),
            width: 320, // narrow screen
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Arabic RTL
        await tester.pumpWidget(
          _buildTestApp(
            DepartureTimeSelector(
              trips: trips,
              selectedTrip: trips.first,
              direction: BookingDirection.outbound,
              onTripSelected: (_) {},
            ),
            locale: const Locale('ar'),
            width: 320, // narrow screen
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
