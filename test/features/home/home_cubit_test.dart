import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/home/data/models/announcement_model.dart';
import 'package:amomy_bus/features/home/data/models/home_summary_model.dart';
import 'package:amomy_bus/features/home/domain/entities/announcement.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/home/domain/repositories/home_repository.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_cubit.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_state.dart';

class MockHomeRepository implements HomeRepository {
  Result<HomeSummary>? summaryResult;
  Result<List<Announcement>>? announcementsResult;

  @override
  ResultFuture<HomeSummary> getHomeSummary() async {
    return summaryResult ??
        const Error(ServerFailure(message: 'Summary not set'));
  }

  @override
  ResultFuture<List<Announcement>> getActiveAnnouncements() async {
    return announcementsResult ?? const Success([]);
  }
}

void main() {
  late MockHomeRepository repository;
  late HomeCubit cubit;

  final sampleSummary = HomeSummary(
    profile: const PassengerProfileSummary(
      fullName: 'Ahmed Commuter',
      avatarUrl: 'https://example.com/avatar.png',
    ),
    availablePoints: 1200,
    upcomingTrip: PassengerUpcomingTrip(
      bookingId: 'b-1',
      tripId: 't-1',
      direction: 'outbound',
      originNameAr: 'ميت فضالة',
      originNameEn: 'Mit Fadala',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      serviceDate: DateTime(2026, 9, 20),
      departureAt: DateTime(2026, 9, 20, 9, 0),
      departureTime: '09:00',
      seatNumber: 'B2',
      farePoints: 30,
      bookingStatus: 'confirmed',
      qrToken: 'sample-qr-token',
    ),
    activity: const PassengerActivityMetrics(
      tripsThisMonth: 2,
      completedTrips: 10,
      pointsSpentThisMonth: 60,
      missedTrips: 0,
    ),
  );

  final sampleAnnouncements = [
    const Announcement(
      id: 'ann-1',
      titleAr: 'تنبيه',
      titleEn: 'Notice',
      descriptionAr: 'وصف',
      descriptionEn: 'Desc',
      type: 'announcement',
    ),
  ];

  setUp(() {
    repository = MockHomeRepository();
    cubit = HomeCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit State Management Tests', () {
    test('Initial state is HomeStatus.initial', () {
      expect(cubit.state.status, equals(HomeStatus.initial));
      expect(cubit.state.summary, isNull);
      expect(cubit.state.announcements, isEmpty);
    });

    test('loadHomeData emits [loading, loaded] on success', () async {
      repository.summaryResult = Success(sampleSummary);
      repository.announcementsResult = Success(sampleAnnouncements);

      final expectedStates = [
        const HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.loaded,
          summary: sampleSummary,
          announcements: sampleAnnouncements,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadHomeData();
    });

    test('loadHomeData emits [loading, error] when summary fails', () async {
      repository.summaryResult =
          const Error(ServerFailure(message: 'Database connection failed'));
      repository.announcementsResult = Success(sampleAnnouncements);

      final expectedStates = [
        const HomeState(status: HomeStatus.loading),
        const HomeState(
          status: HomeStatus.error,
          errorMessage: 'Database connection failed',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadHomeData();
    });

    test(
        'Resilience: Announcements failure does NOT break Home summary loaded state',
        () async {
      repository.summaryResult = Success(sampleSummary);
      repository.announcementsResult =
          const Error(ServerFailure(message: 'Announcements unavailable'));

      final expectedStates = [
        const HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.loaded,
          summary: sampleSummary,
          announcements: const [],
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadHomeData();
    });
  });

  group('Home Models Data Parsing Tests', () {
    test('HomeSummaryModel parses backend JSON payload correctly', () {
      final json = {
        'profile': {
          'full_name': 'Ali Abdelnaser',
          'avatar_url': 'https://amomy.com/avatar.jpg',
        },
        'wallet': {
          'available_points': 1500,
        },
        'upcoming_trip': {
          'booking_id': 'b-99',
          'trip_id': 't-99',
          'direction': 'return',
          'origin_name_ar': 'المنصورة',
          'origin_name_en': 'Mansoura',
          'destination_name_ar': 'ميت فضالة',
          'destination_name_en': 'Mit Fadala',
          'service_date': '2026-09-18',
          'departure_at': '2026-09-18T14:30:00Z',
          'departure_time': '16:30',
          'seat_number': 'C4',
          'fare_points': 25,
          'booking_status': 'confirmed',
          'qr_token': 'test-qr-code',
        },
        'activity': {
          'trips_this_month': 4,
          'completed_trips': 15,
          'points_spent_this_month': 100,
          'missed_trips': 0,
        },
      };

      final model = HomeSummaryModel.fromJson(json);

      expect(model.profile.fullName, equals('Ali Abdelnaser'));
      expect(model.profile.firstName, equals('Ali'));
      expect(model.profile.initials, equals('AA'));
      expect(model.availablePoints, equals(1500));
      expect(model.upcomingTrip, isNotNull);
      expect(model.upcomingTrip!.seatNumber, equals('C4'));
      expect(model.upcomingTrip!.farePoints, equals(25));
      expect(model.upcomingTrip!.originName('ar'), equals('المنصورة'));
      expect(model.upcomingTrip!.destinationName('en'), equals('Mit Fadala'));
      expect(model.activity.tripsThisMonth, equals(4));
      expect(model.activity.completedTrips, equals(15));
      expect(model.activity.pointsSpentThisMonth, equals(100));
      expect(model.activity.missedTrips, equals(0));
    });

    test('AnnouncementModel parses backend JSON payload correctly', () {
      final json = {
        'id': 'ann-101',
        'title_ar': 'تنبيه هام',
        'title_en': 'Important Alert',
        'description_ar': 'تم تعديل مواعيد الرحلة الصباحية',
        'description_en': 'Morning trip departure schedule updated',
        'type': 'announcement',
        'sort_order': 1,
        'starts_at': '2026-09-11T00:00:00Z',
        'ends_at': '2026-09-20T00:00:00Z',
      };

      final model = AnnouncementModel.fromJson(json);

      expect(model.id, equals('ann-101'));
      expect(model.localizedTitle('ar'), equals('تنبيه هام'));
      expect(model.localizedTitle('en'), equals('Important Alert'));
      expect(model.isOffer, isFalse);
    });
  });
}
