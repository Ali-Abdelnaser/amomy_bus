import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/home/domain/entities/announcement.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_cubit.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_state.dart';
import 'package:amomy_bus/features/home/presentation/pages/passenger_home_page.dart';
import 'package:amomy_bus/features/home/presentation/widgets/amomy_announcement_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_activity_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_announcements_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_app_bar.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_upcoming_trip_card.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_summary.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';

class _MockTrackingRepo implements TrackingRepository {
  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    return const TrackingSummary(
      status: LiveTrackingStatus.offline,
      routeStops: [],
      isInServiceWindow: false,
      serviceWindow: 'closed',
      cairoTime: '12:00:00',
      cairoDate: '2026-09-14',
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

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<TrackingRepository>()) {
      getIt.registerSingleton<TrackingRepository>(_MockTrackingRepo());
    }
  });

  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
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
      home: child,
    );
  }

  final testSummary = HomeSummary(
    profile: const PassengerProfileSummary(
      fullName: 'Ali Commuter',
      avatarUrl: null,
    ),
    availablePoints: 2450,
    upcomingTrip: PassengerUpcomingTrip(
      bookingId: 'bkg-123',
      tripId: 'trip-456',
      direction: 'outbound',
      originNameAr: 'ميت فضالة',
      originNameEn: 'Mit Fadala',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      serviceDate: DateTime(2026, 9, 15),
      departureAt: DateTime(2026, 9, 15, 8, 30),
      departureTime: '08:30',
      seatNumber: 'A1',
      farePoints: 30,
      bookingStatus: 'confirmed',
      qrToken: 'test-qr-token-12345',
    ),
    activity: const PassengerActivityMetrics(
      tripsThisMonth: 6,
      completedTrips: 18,
      pointsSpentThisMonth: 180,
      missedTrips: 0,
    ),
  );

  final testAnnouncements = [
    const Announcement(
      id: 'ann-1',
      titleAr: 'تنبيه الرحلات',
      titleEn: 'Trip Alert',
      descriptionAr: 'تابع مواعيد رحلاتك من التطبيق قبل التحرك.',
      descriptionEn: 'Track your trip schedules from the app before departure.',
      type: 'announcement',
      sortOrder: 1,
    ),
    const Announcement(
      id: 'ann-2',
      titleAr: 'عروض عمومي',
      titleEn: 'Amomy Offers',
      descriptionAr: 'اشحن رصيدك واستفد من العرض الحالي.',
      descriptionEn: 'Recharge your balance and enjoy the current offer.',
      type: 'offer',
      sortOrder: 2,
    ),
  ];

  group('Passenger Home Screen UI Tests', () {
    testWidgets('Home bell unread badge handles 0, 1, 9, and 10+', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: HomeAppBar(
              fullName: 'Ali Commuter',
              unreadNotificationsCount: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);
      expect(find.text('9'), findsNothing);
      expect(find.text('9+'), findsNothing);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: HomeAppBar(
              fullName: 'Ali Commuter',
              unreadNotificationsCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: HomeAppBar(
              fullName: 'Ali Commuter',
              unreadNotificationsCount: 9,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: HomeAppBar(
              fullName: 'Ali Commuter',
              unreadNotificationsCount: 10,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('Renders all 6 core production sections in loaded state', (
      tester,
    ) async {
      final cubit = HomeCubit.idle(
        initialState: HomeState(
          status: HomeStatus.loaded,
          summary: testSummary,
          announcements: testAnnouncements,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(PassengerHomePage(homeCubit: cubit)),
      );
      await tester.pumpAndSettle();

      // 1. Custom App Bar
      expect(find.byType(HomeAppBar), findsOneWidget);
      expect(find.text('AMOMY'), findsOneWidget);
      expect(find.text('AC'), findsOneWidget);

      // 2. Announcements Carousel
      expect(find.byType(HomeAnnouncementsSection), findsOneWidget);

      // 3. Book Your Ride Card (with integrated points balance)
      expect(find.byType(HomeBookRideCard), findsOneWidget);
      expect(find.textContaining('2,450'), findsOneWidget);
      expect(find.text('Book Your Ride'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);

      // 4. Upcoming Trip
      expect(find.byType(HomeUpcomingTripCard), findsOneWidget);
      expect(find.text('Mit Fadala'), findsOneWidget);
      expect(find.text('Mansoura'), findsOneWidget);
      expect(find.text('8:30 AM'), findsOneWidget);
      expect(find.textContaining('A1'), findsOneWidget);
      expect(find.text('View Ticket'), findsOneWidget);

      // 5. Your Activity (with circular progress & transit metrics)
      expect(find.byType(HomeActivitySection), findsOneWidget);
      expect(find.text('Your Activity'), findsOneWidget);
      expect(find.text('Trips This Month'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Completed Trips'), findsOneWidget);
      expect(find.text('Points Spent This Month'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('No missed trips this month.'), findsOneWidget);
    });

    testWidgets('Hides Announcements section cleanly when empty', (
      tester,
    ) async {
      final cubit = HomeCubit.idle(
        initialState: HomeState(
          status: HomeStatus.loaded,
          summary: testSummary,
          announcements: const [],
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(PassengerHomePage(homeCubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeAnnouncementsSection), findsNothing);
      expect(find.byType(AmomyAnnouncementCard), findsNothing);
    });

    testWidgets('Renders clean empty state when there is no upcoming trip', (
      tester,
    ) async {
      final summaryNoTrip = HomeSummary(
        profile: testSummary.profile,
        availablePoints: 500,
        upcomingTrip: null,
        activity: const PassengerActivityMetrics(
          tripsThisMonth: 0,
          completedTrips: 0,
          pointsSpentThisMonth: 0,
          missedTrips: 0,
        ),
      );

      final cubit = HomeCubit.idle(
        initialState: HomeState(
          status: HomeStatus.loaded,
          summary: summaryNoTrip,
          announcements: const [],
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(PassengerHomePage(homeCubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No upcoming trips'), findsOneWidget);
      expect(find.text('Book a Ride'), findsOneWidget);
      expect(find.text('View Ticket'), findsNothing);
    });

    testWidgets('Renders RTL Arabic properly', (tester) async {
      final cubit = HomeCubit.idle(
        initialState: HomeState(
          status: HomeStatus.loaded,
          summary: testSummary,
          announcements: testAnnouncements,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          PassengerHomePage(homeCubit: cubit),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AMOMY'), findsOneWidget);
      expect(find.textContaining('2,450'), findsOneWidget);
      expect(find.text('احجز رحلتك'), findsOneWidget);
      expect(find.text('احجز الآن'), findsOneWidget);
      expect(find.text('رحلتك القادمة'), findsOneWidget);
      expect(find.text('ميت فضالة'), findsOneWidget);
      expect(find.text('المنصورة'), findsOneWidget);
      expect(find.text('عرض التذكرة'), findsOneWidget);
      expect(find.text('نشاطك'), findsOneWidget);
      expect(find.text('رحلات هذا الشهر'), findsOneWidget);
    });

    testWidgets(
      'Displays authoritative live points from shared WalletCubit instead of stale home summary',
      (tester) async {
        final homeCubit = HomeCubit.idle(
          initialState: HomeState(
            status: HomeStatus.loaded,
            summary: testSummary, // has availablePoints: 2450
            announcements: testAnnouncements,
          ),
        );

        final walletCubit = FakeWalletCubit(
          const WalletState(
            status: WalletStatus.loaded,
            summary: WalletSummary(
              totalAvailablePoints: 500,
              cashPoints: 500,
              subscriptionPoints: 0,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            PassengerHomePage(homeCubit: homeCubit, walletCubit: walletCubit),
          ),
        );
        await tester.pumpAndSettle();

        // Must display 500 from the authoritative WalletCubit, NOT 2,450 from stale summary
        expect(find.textContaining('500'), findsOneWidget);
        expect(find.textContaining('2,450'), findsNothing);
      },
    );
  });
}

class FakeWalletCubit extends Cubit<WalletState> implements WalletCubit {
  FakeWalletCubit(super.initialState);

  @override
  Future<void> loadWalletSummary(String userId) async {}

  @override
  Future<void> loadMoreHistory() async {}
}
