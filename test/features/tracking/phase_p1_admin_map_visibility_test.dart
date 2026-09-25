import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:amomy_bus/features/tracking/presentation/screens/live_map_screen.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _MockTrackingRepo extends TrackingRepository {
  TrackingSummary? trackingSummary;
  final StreamController<void> invalidationStream =
      StreamController<void>.broadcast();

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    return trackingSummary ??
        TrackingSummary.fromJson({
          'trip_id': tripId,
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
        });
  }

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) {
    return invalidationStream.stream;
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) async => false;

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

Widget _wrapWithLocalization(
  Widget child, {
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase P1 — Domain Models & Parser Precedence', () {
    test('1 & 2: TrackingPhase parses map_disabled and bus_hidden', () {
      expect(
        TrackingPhase.fromString('map_disabled'),
        equals(TrackingPhase.mapDisabled),
      );
      expect(
        TrackingPhase.fromString('bus_hidden'),
        equals(TrackingPhase.busHidden),
      );
      expect(TrackingPhase.mapDisabled.isAdminDisabled, isTrue);
      expect(TrackingPhase.busHidden.isAdminDisabled, isTrue);
      expect(TrackingPhase.live.isAdminDisabled, isFalse);
    });

    test('3, 4, 5: TrackingSummary parses additive fields', () {
      final json = {
        'trip_id': 'trip-123',
        'tracking_status': 'offline',
        'tracking_phase': 'map_disabled',
        'tracking_enabled': false,
        'passenger_map_enabled': false,
        'bus_visible_on_passenger_map': true,
        'map_visibility_state': 'global_disabled',
      };

      final summary = TrackingSummary.fromJson(json);
      expect(summary.passengerMapEnabled, isFalse);
      expect(summary.busVisibleOnPassengerMap, isTrue);
      expect(summary.mapVisibilityState, equals('global_disabled'));
      expect(summary.trackingPhase, equals(TrackingPhase.mapDisabled));
      expect(summary.trackingEnabled, isFalse);
    });

    test(
      '6: Missing additive fields preserve backwards-compatible defaults',
      () {
        final json = {
          'trip_id': 'trip-legacy',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
        };

        final summary = TrackingSummary.fromJson(json);
        expect(summary.passengerMapEnabled, isTrue);
        expect(summary.busVisibleOnPassengerMap, isTrue);
        expect(summary.mapVisibilityState, equals('visible'));
      },
    );

    test(
      '7 & 8: map_disabled and bus_hidden are NOT converted to gpsOffline on departed trips',
      () {
        final jsonDisabled = {
          'trip_id': 'trip-123',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'map_disabled',
          'tracking_enabled': false,
          'passenger_map_enabled': false,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'global_disabled',
        };
        final summaryDisabled = TrackingSummary.fromJson(jsonDisabled);
        expect(
          summaryDisabled.trackingPhase,
          equals(TrackingPhase.mapDisabled),
        );
        expect(summaryDisabled.trackingEnabled, isFalse);

        final jsonHidden = {
          'trip_id': 'trip-456',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'bus_hidden',
          'tracking_enabled': false,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': false,
          'map_visibility_state': 'bus_hidden',
        };
        final summaryHidden = TrackingSummary.fromJson(jsonHidden);
        expect(summaryHidden.trackingPhase, equals(TrackingPhase.busHidden));
        expect(summaryHidden.trackingEnabled, isFalse);
      },
    );

    test(
      '9: trackingEnabled remains false in admin-hidden states even when tripStatus is departed',
      () {
        final json = {
          'trip_id': 'trip-789',
          'trip_status': 'departed',
          'started_at': '2026-09-24T08:00:00Z',
          'tracking_status': 'offline',
          'tracking_phase': 'bus_hidden',
          'tracking_enabled': false,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': false,
          'map_visibility_state': 'bus_hidden',
        };
        final summary = TrackingSummary.fromJson(json);
        expect(summary.trackingEnabled, isFalse);

        final state = TrackingState(
          trackedTripId: 'trip-789',
          summary: summary,
        );
        expect(state.trackingEnabled, isFalse);
        expect(state.trackingPhase, equals(TrackingPhase.busHidden));
        expect(state.isAdminDisabled, isTrue);
        expect(state.isOffline, isFalse); // Not treated as telemetry offline
      },
    );
  });

  group('Phase P1 — UI Lifecycle & Calm State Presentation', () {
    testWidgets(
      '10 & 11: Global disabled renders calm Arabic copy without GPS error',
      (tester) async {
        final repo = _MockTrackingRepo()
          ..trackingSummary = TrackingSummary.fromJson({
            'trip_id': 'trip-p1',
            'trip_status': 'departed',
            'tracking_status': 'offline',
            'tracking_phase': 'map_disabled',
            'tracking_enabled': false,
            'passenger_map_enabled': false,
            'bus_visible_on_passenger_map': true,
            'map_visibility_state': 'global_disabled',
          });
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-p1');

        await tester.pumpWidget(
          _wrapWithLocalization(
            LiveMapScreen(trackingCubit: cubit, tripId: 'trip-p1'),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الخريطة غير متاحة حالياً'), findsOneWidget);
        expect(
          find.text('تم إيقاف عرض الموقع المباشر بواسطة الإدارة.'),
          findsOneWidget,
        );
        expect(find.byType(GoogleMap), findsNothing);
        expect(find.text('تعذر استقبال إشارة الـ GPS'), findsNothing);
      },
    );

    testWidgets('Global disabled renders calm English copy', (tester) async {
      final repo = _MockTrackingRepo()
        ..trackingSummary = TrackingSummary.fromJson({
          'trip_id': 'trip-p1',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'map_disabled',
          'tracking_enabled': false,
          'passenger_map_enabled': false,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'global_disabled',
        });
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-p1');

      await tester.pumpWidget(
        _wrapWithLocalization(
          LiveMapScreen(trackingCubit: cubit, tripId: 'trip-p1'),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live map is currently unavailable'), findsOneWidget);
      expect(
        find.text(
          'Live location display has been disabled by the administration.',
        ),
        findsOneWidget,
      );
      expect(find.byType(GoogleMap), findsNothing);
    });

    testWidgets(
      '12 & 13: Bus hidden renders calm Arabic copy without GPS error',
      (tester) async {
        final repo = _MockTrackingRepo()
          ..trackingSummary = TrackingSummary.fromJson({
            'trip_id': 'trip-p1',
            'trip_status': 'departed',
            'tracking_status': 'offline',
            'tracking_phase': 'bus_hidden',
            'tracking_enabled': false,
            'passenger_map_enabled': true,
            'bus_visible_on_passenger_map': false,
            'map_visibility_state': 'bus_hidden',
          });
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-p1');

        await tester.pumpWidget(
          _wrapWithLocalization(
            LiveMapScreen(trackingCubit: cubit, tripId: 'trip-p1'),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('الموقع المباشر غير متاح لهذه الرحلة'),
          findsOneWidget,
        );
        expect(find.text('عرض موقع الحافلة متوقف حالياً.'), findsOneWidget);
        expect(find.byType(GoogleMap), findsNothing);
        expect(find.text('تعذر استقبال إشارة الـ GPS'), findsNothing);
      },
    );

    testWidgets('Bus hidden renders calm English copy', (tester) async {
      final repo = _MockTrackingRepo()
        ..trackingSummary = TrackingSummary.fromJson({
          'trip_id': 'trip-p1',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'bus_hidden',
          'tracking_enabled': false,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': false,
          'map_visibility_state': 'bus_hidden',
        });
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-p1');

      await tester.pumpWidget(
        _wrapWithLocalization(
          LiveMapScreen(trackingCubit: cubit, tripId: 'trip-p1'),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Live location is unavailable for this trip'),
        findsOneWidget,
      );
      expect(
        find.text('Live bus location display is currently turned off.'),
        findsOneWidget,
      );
      expect(find.byType(GoogleMap), findsNothing);
    });

    testWidgets(
      'Home Live Tracking Card displays mapDisabled and busHidden calm messages',
      (tester) async {
        final summaryDisabled = TrackingSummary.fromJson({
          'trip_id': 'trip-card-1',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'map_disabled',
          'tracking_enabled': false,
          'passenger_map_enabled': false,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'global_disabled',
        });

        final cubit = TrackingCubit(repository: _MockTrackingRepo());
        cubit.emit(
          TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            summary: summaryDisabled,
            trackedTripId: 'trip-card-1',
          ),
        );

        await tester.pumpWidget(
          _wrapWithLocalization(
            BlocProvider.value(
              value: cubit,
              child: const Scaffold(body: HomeLiveTrackingCard()),
            ),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الخريطة غير متاحة حالياً'), findsOneWidget);
        expect(
          find.text('تم إيقاف عرض الموقع المباشر بواسطة الإدارة.'),
          findsOneWidget,
        );
        expect(find.text('موقع الحافلة غير متاح مؤقتًا'), findsNothing);
        expect(find.byKey(const Key('home_tracking_offline_map_background')), findsOneWidget);
        expect(find.byKey(const Key('home_tracking_offline_scrim')), findsOneWidget);
        expect(find.byKey(const Key('home_tracking_disabled_action_button')), findsOneWidget);
        expect(find.byType(GoogleMap), findsNothing);

        // Now test busHidden
        final summaryHidden = TrackingSummary.fromJson({
          'trip_id': 'trip-card-2',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'bus_hidden',
          'tracking_enabled': false,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': false,
          'map_visibility_state': 'bus_hidden',
        });

        cubit.emit(
          TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            summary: summaryHidden,
            trackedTripId: 'trip-card-2',
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('الموقع المباشر غير متاح لهذه الرحلة'),
          findsOneWidget,
        );
        expect(find.text('عرض موقع الحافلة متوقف حالياً.'), findsOneWidget);
        expect(find.text('موقع الحافلة غير متاح مؤقتًا'), findsNothing);
        expect(find.byKey(const Key('home_tracking_offline_map_background')), findsOneWidget);
        expect(find.byKey(const Key('home_tracking_offline_scrim')), findsOneWidget);
        expect(find.byKey(const Key('home_tracking_disabled_action_button')), findsOneWidget);
        expect(find.byType(GoogleMap), findsNothing);
      },
    );

    testWidgets(
      '23: LiveMapScreen with null tripId renders clean empty state',
      (tester) async {
        final cubit = TrackingCubit(repository: _MockTrackingRepo());
        await tester.pumpWidget(
          _wrapWithLocalization(
            LiveMapScreen(trackingCubit: cubit, tripId: null),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('اختر رحلة لعرض التتبع'), findsOneWidget);
        expect(
          find.text('يمكنك فتح التتبع المباشر من تفاصيل رحلتك.'),
          findsOneWidget,
        );
        expect(find.text('عرض رحلاتي'), findsOneWidget);
        expect(find.byType(GoogleMap), findsNothing);
      },
    );

    testWidgets(
      '24: HomeLiveTrackingCard with null summary remains visible in offline calm state with map background, scrim, and disabled action',
      (tester) async {
        final cubit = TrackingCubit(repository: _MockTrackingRepo());
        bool mapTapped = false;
        // Idle initial state: summary == null
        expect(cubit.state.summary, isNull);

        // Test in Arabic
        await tester.pumpWidget(
          _wrapWithLocalization(
            BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: HomeLiveTrackingCard(
                  onViewMapTap: () {
                    mapTapped = true;
                  },
                ),
              ),
            ),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Remains visible in home
        expect(find.byType(HomeLiveTrackingCard), findsOneWidget);
        expect(find.text('لا توجد رحلة نشطة'), findsOneWidget);
        expect(find.text('غير متصل'), findsWidgets);

        // 2. Map-style visual background and calm scrim exist
        expect(
          find.byKey(const Key('home_tracking_offline_map_background')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_tracking_offline_scrim')),
          findsOneWidget,
        );

        // 3. No fake bus marker, no fake ETA, no fake stop progress
        expect(find.byType(GoogleMap), findsNothing);
        expect(find.textContaining('دقيقة'), findsNothing);
        expect(find.text('تصل خلال'), findsNothing);
        expect(find.text('المحطة السابقة'), findsNothing);
        expect(find.text('المحطة التالية'), findsNothing);

        // 4. Action button exists but is disabled (tapping does nothing)
        expect(
          find.byKey(const Key('home_tracking_disabled_action_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_tracking_active_action_button')),
          findsNothing,
        );
        await tester.tap(find.byKey(const Key('home_tracking_disabled_action_button')));
        await tester.pump();
        expect(mapTapped, isFalse);

        // Test in English
        await tester.pumpWidget(
          _wrapWithLocalization(
            BlocProvider.value(
              value: cubit,
              child: const Scaffold(body: HomeLiveTrackingCard()),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeLiveTrackingCard), findsOneWidget);
        expect(find.text('Trip tracking is not active'), findsOneWidget);
        expect(find.text('OFFLINE'), findsWidgets);
        expect(
          find.byKey(const Key('home_tracking_offline_map_background')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '25: HomeLiveTrackingCard transitions to active live state with live map and active button',
      (tester) async {
        final repo = _MockTrackingRepo();
        final cubit = TrackingCubit(repository: repo);
        bool liveMapTapped = false;

        final summaryLive = TrackingSummary.fromJson({
          'trip_id': 'trip-live-1',
          'trip_status': 'departed',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'latitude': 31.05,
          'longitude': 31.38,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'visible',
        });

        cubit.emit(
          TrackingState(
            uiStatus: TrackingUiStatus.loaded,
            summary: summaryLive,
            trackedTripId: 'trip-live-1',
          ),
        );

        await tester.pumpWidget(
          _wrapWithLocalization(
            BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: HomeLiveTrackingCard(
                  onViewMapTap: () {
                    liveMapTapped = true;
                  },
                ),
              ),
            ),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Live card renders LiveBusMapWidget
        expect(find.byType(HomeLiveTrackingCard), findsOneWidget);
        expect(find.byType(LiveBusMapWidget), findsOneWidget);

        // 2. Offline decorative map background and scrim are removed
        expect(
          find.byKey(const Key('home_tracking_offline_map_background')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('home_tracking_offline_scrim')),
          findsNothing,
        );

        // 3. Active button is enabled and clickable
        expect(
          find.byKey(const Key('home_tracking_active_action_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_tracking_disabled_action_button')),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('home_tracking_active_action_button')));
        await tester.pump();
        expect(liveMapTapped, isTrue);
      },
    );
  });

  group('Phase P1 — Critical Privacy & Realtime Behavior', () {
    test(
      '21a: canShowBusMarker returns true only when telemetry exists and status is live/online/stale/progressionUnavailable',
      () {
        final tel = BusTelemetry(
          latitude: 31.0409,
          longitude: 31.3785,
          speedKmh: 40.0,
          heading: 90,
          gpsRecordedAt: DateTime.now(),
        );

        // Visible states
        expect(
          LiveBusMapWidget.canShowBusMarker(
            telemetry: tel,
            status: LiveTrackingStatus.live,
          ),
          isTrue,
        );
        expect(
          LiveBusMapWidget.canShowBusMarker(
            telemetry: tel,
            status: LiveTrackingStatus.online,
          ),
          isTrue,
        );
        expect(
          LiveBusMapWidget.canShowBusMarker(
            telemetry: tel,
            status: LiveTrackingStatus.stale,
          ),
          isTrue,
        );

        // Privacy / Hidden states: telemetry is null -> MUST BE FALSE
        expect(
          LiveBusMapWidget.canShowBusMarker(
            telemetry: null,
            status: LiveTrackingStatus.offline,
          ),
          isFalse,
        );
        expect(
          LiveBusMapWidget.canShowBusMarker(
            telemetry: null,
            status: LiveTrackingStatus.live,
          ),
          isFalse,
        );
      },
    );

    test(
      '21b: When telemetry becomes null, cached location and marker are cleared',
      () {
        final initialTel = BusTelemetry(
          latitude: 31.0409,
          longitude: 31.3785,
          speedKmh: 40.0,
          heading: 90,
          gpsRecordedAt: DateTime.now(),
        );

        // 1. Initial visible state
        final visibleState = LiveBusMapWidget.resolveMapStateOnTelemetryChange(
          currentDisplayedPosition: null,
          oldTelemetry: null,
          newTelemetry: initialTel,
          status: LiveTrackingStatus.live,
        );
        expect(
          visibleState.displayedPosition,
          equals(const LatLng(31.0409, 31.3785)),
        );
        expect(visibleState.shouldShowMarker, isTrue);
        expect(visibleState.isCleared, isFalse);

        // 2. Admin hides Bus / Map -> telemetry becomes null
        final hiddenState = LiveBusMapWidget.resolveMapStateOnTelemetryChange(
          currentDisplayedPosition: visibleState.displayedPosition,
          oldTelemetry: initialTel,
          newTelemetry: null,
          status: LiveTrackingStatus.offline,
        );

        // Assertions required by Phase P1 Rule 21:
        // - old Bus marker is gone
        // - old displayed coordinate is not used
        // - cached position is cleared
        // - no stale location remains visible
        expect(hiddenState.shouldShowMarker, isFalse);
        expect(hiddenState.displayedPosition, isNull);
        expect(hiddenState.isCleared, isTrue);

        // 3. Re-enable transition: visible again with NEW coordinate
        final newTel = BusTelemetry(
          latitude: 31.0600,
          longitude: 31.3900,
          speedKmh: 35.0,
          heading: 180,
          gpsRecordedAt: DateTime.now(),
        );

        final reEnabledState =
            LiveBusMapWidget.resolveMapStateOnTelemetryChange(
              currentDisplayedPosition: hiddenState.displayedPosition,
              oldTelemetry: null,
              newTelemetry: newTel,
              status: LiveTrackingStatus.live,
            );

        // Assertions:
        // - The re-enabled state must use the new backend coordinate
        // - Never the previous hidden coordinate (31.0409, 31.3785)
        expect(reEnabledState.shouldShowMarker, isTrue);
        expect(reEnabledState.isCleared, isFalse);
        expect(
          reEnabledState.displayedPosition,
          equals(const LatLng(31.0600, 31.3900)),
        );
        expect(
          reEnabledState.displayedPosition,
          isNot(equals(const LatLng(31.0409, 31.3785))),
        );
      },
    );

    test(
      '22: Realtime invalidation triggers reload and supports mapDisabled -> live transition',
      () async {
        final repo = _MockTrackingRepo();
        final cubit = TrackingCubit(repository: repo);

        // 1. Initial State: Live
        repo.trackingSummary = TrackingSummary.fromJson({
          'trip_id': 'trip-rt',
          'trip_status': 'departed',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'latitude': 31.05,
          'longitude': 31.38,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'visible',
        });

        await cubit.loadTrackingData(tripId: 'trip-rt');
        expect(cubit.state.trackingPhase, equals(TrackingPhase.live));
        expect(cubit.state.isLive, isTrue);

        // 2. Admin disables map -> realtime event arrives
        repo.trackingSummary = TrackingSummary.fromJson({
          'trip_id': 'trip-rt',
          'trip_status': 'departed',
          'tracking_status': 'offline',
          'tracking_phase': 'map_disabled',
          'tracking_enabled': false,
          'latitude': null,
          'longitude': null,
          'passenger_map_enabled': false,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'global_disabled',
        });

        // Fire realtime stream
        repo.invalidationStream.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(cubit.state.trackingPhase, equals(TrackingPhase.mapDisabled));
        expect(cubit.state.isAdminDisabled, isTrue);
        expect(cubit.state.isMapDisabled, isTrue);
        expect(cubit.state.latestTelemetry, isNull);

        // 3. Admin re-enables map -> realtime event arrives
        repo.trackingSummary = TrackingSummary.fromJson({
          'trip_id': 'trip-rt',
          'trip_status': 'departed',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'latitude': 31.06,
          'longitude': 31.39,
          'passenger_map_enabled': true,
          'bus_visible_on_passenger_map': true,
          'map_visibility_state': 'visible',
        });

        // Fire realtime stream
        repo.invalidationStream.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(cubit.state.trackingPhase, equals(TrackingPhase.live));
        expect(cubit.state.isLive, isTrue);
        expect(cubit.state.latestTelemetry?.latitude, equals(31.06));

        await cubit.close();
      },
    );
  });
}
