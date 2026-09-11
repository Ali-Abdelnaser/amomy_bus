import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_entities.dart';
import '../models/booking_models.dart';

abstract class BookingRemoteDataSource {
  Future<List<TripOptionModel>> getAvailableTrips({
    required String direction,
    required String date,
  });

  Future<List<TripSeatModel>> getTripSeatMap({
    required String tripId,
  });

  Future<BookingHoldModel> createBookingHold({
    required String tripId,
    required String seatId,
  });

  Future<void> releaseBookingHold({
    required String holdId,
  });

  Future<PassengerBookingModel> confirmBooking({
    required String holdId,
  });

  Future<List<PassengerBookingModel>> getPassengerBookings();

  Stream<void> subscribeToTripSeatUpdates(String tripId);
}

@LazySingleton(as: BookingRemoteDataSource)
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient _supabase;

  BookingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<TripOptionModel>> getAvailableTrips({
    required String direction,
    required String date,
  }) async {
    final response = await _supabase.rpc(
      'get_available_trips',
      params: {
        'p_direction': direction,
        'p_date': date,
      },
    );

    final list = response as List<dynamic>;
    return list
        .map((e) => TripOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TripSeatModel>> getTripSeatMap({
    required String tripId,
  }) async {
    final response = await _supabase.rpc(
      'get_trip_seat_map',
      params: {
        'p_trip_id': tripId,
      },
    );

    final list = response as List<dynamic>;
    return list
        .map((e) => TripSeatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookingHoldModel> createBookingHold({
    required String tripId,
    required String seatId,
  }) async {
    final response = await _supabase.rpc(
      'create_booking_hold',
      params: {
        'p_trip_id': tripId,
        'p_seat_id': seatId,
      },
    );

    return BookingHoldModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> releaseBookingHold({
    required String holdId,
  }) async {
    await _supabase.rpc(
      'release_booking_hold',
      params: {
        'p_hold_id': holdId,
      },
    );
  }

  @override
  Future<PassengerBookingModel> confirmBooking({
    required String holdId,
  }) async {
    final response = await _supabase.rpc(
      'confirm_booking',
      params: {
        'p_hold_id': holdId,
      },
    );

    final bookingJson = response as Map<String, dynamic>;
    final bookingId = bookingJson['booking_id'] as String;

    final bookingRecords = await getPassengerBookings();
    return bookingRecords.firstWhere(
      (b) => b.bookingId == bookingId,
      orElse: () => PassengerBookingModel(
        bookingId: bookingId,
        tripId: bookingJson['trip_id'] as String? ?? '',
        direction: BookingDirection.outbound,
        originNameAr: '',
        originNameEn: '',
        destinationNameAr: '',
        destinationNameEn: '',
        serviceDate: DateTime.now(),
        departureTime: '',
        departureAt: DateTime.now(),
        seatNumber: bookingJson['seat_number'] as String? ?? '',
        farePoints: (bookingJson['fare_points'] as num? ?? 50).toDouble(),
        status: 'confirmed',
        qrToken: bookingJson['qr_token'] as String? ?? '',
        bookedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<PassengerBookingModel>> getPassengerBookings() async {
    final response = await _supabase.rpc('get_passenger_bookings');
    final list = response as List<dynamic>;
    return list
        .map((e) => PassengerBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _supabase.channel('trip_seats_$tripId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'seat_holds',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'trip_id',
                value: tripId,
              ),
              callback: (_) {
                if (!controller.isClosed) controller.add(null);
              },
            )
            .subscribe();
      },
      onCancel: () {
        if (channel != null) {
          _supabase.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }
}
