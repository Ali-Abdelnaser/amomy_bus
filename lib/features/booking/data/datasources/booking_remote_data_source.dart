import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_entities.dart';
import '../models/booking_models.dart';

abstract class BookingRemoteDataSource {
  Future<List<RouteStopModel>> getRouteStops({required String direction});

  Future<List<TripOptionModel>> getAvailableTrips({
    required String direction,
    String? date,
    String? routeStopId,
  });

  Future<List<TripSeatModel>> getTripSeatMap({required String tripId});

  Future<BookingHoldModel> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  });

  Future<void> releaseBookingHold({required String holdId});

  Future<PassengerBookingModel> confirmBooking({required String holdId});

  Future<List<PassengerBookingModel>> getPassengerBookings();

  Future<List<PassengerTodayTripModel>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  });

  Future<PassengerTripPreferenceModel?> getMyTripPreferences();

  Future<PassengerTripPreferenceModel> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  });

  Future<void> cancelBooking(String bookingId);

  Future<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  });

  Future<List<RoundTripReturnOptionModel>> getRoundTripReturnOptions({
    required String outboundTripId,
    required String outboundRouteStopId,
  });

  Future<RoundTripBundleHoldModel> createRoundTripBundleHold({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  });

  Future<RoundTripBundleHoldModel> setRoundTripReturnSeat({
    required String bundleHoldId,
    required String returnSeatId,
  });

  Future<void> releaseRoundTripBundleHold({required String bundleHoldId});

  Future<RoundTripConfirmationModel> confirmRoundTripBundle({
    required String bundleHoldId,
  });

  Future<RoundTripBundleContextModel> getRoundTripBundleContext({
    required String bookingId,
  });

  Stream<void> subscribeToTripSeatUpdates(String tripId);

  Stream<void> subscribeToPassengerBookingUpdates();
}

@LazySingleton(as: BookingRemoteDataSource)
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient _supabase;

  BookingRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<RouteStopModel>> getRouteStops({
    required String direction,
  }) async {
    final response = await _supabase.rpc(
      'get_route_stops',
      params: {'p_direction': direction},
    );

    final list = response as List<dynamic>;
    return list
        .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TripOptionModel>> getAvailableTrips({
    required String direction,
    String? date,
    String? routeStopId,
  }) async {
    final params = <String, dynamic>{'p_direction': direction};
    if (routeStopId != null) {
      params['p_route_stop_id'] = routeStopId;
    }

    final response = await _supabase.rpc(
      'get_today_available_trips',
      params: params,
    );

    final list = response as List<dynamic>;
    return list
        .map((e) => TripOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TripSeatModel>> getTripSeatMap({required String tripId}) async {
    final response = await _supabase.rpc(
      'get_trip_seat_map',
      params: {'p_trip_id': tripId},
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
    String? routeStopId,
    String? destinationRouteStopId,
  }) async {
    final params = <String, dynamic>{'p_trip_id': tripId, 'p_seat_id': seatId};
    if (routeStopId != null) {
      params['p_route_stop_id'] = routeStopId;
    }
    if (destinationRouteStopId != null) {
      params['p_destination_route_stop_id'] = destinationRouteStopId;
    }

    final response = await _supabase.rpc('create_booking_hold', params: params);

    return BookingHoldModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> releaseBookingHold({required String holdId}) async {
    await _supabase.rpc('release_booking_hold', params: {'p_hold_id': holdId});
  }

  @override
  Future<PassengerBookingModel> confirmBooking({required String holdId}) async {
    final response = await _supabase.rpc(
      'confirm_booking',
      params: {'p_hold_id': holdId},
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
        seatNumber:
            (bookingJson['seat'] ?? bookingJson['seat_number']) as String? ??
            '',
        farePoints: (bookingJson['fare_points'] as num? ?? 0).toDouble(),
        status: 'confirmed',
        qrToken: bookingJson['qr_token'] as String? ?? '',
        bookedAt: DateTime.now(),
        routeStopId: bookingJson['route_stop_id'] as String?,
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
  Future<List<PassengerTodayTripModel>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async {
    final params = <String, dynamic>{};
    if (direction != null) {
      params['p_direction'] = direction;
    }
    if (originRouteStopId != null) {
      params['p_origin_route_stop_id'] = originRouteStopId;
    }

    final response = await _supabase.rpc(
      'get_passenger_today_trips',
      params: params,
    );

    final list = response as List<dynamic>;
    return list
        .map((e) => PassengerTodayTripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PassengerTripPreferenceModel?> getMyTripPreferences() async {
    final response = await _supabase.rpc('get_my_trip_preferences');
    if (response == null) return null;
    return PassengerTripPreferenceModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<PassengerTripPreferenceModel> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async {
    final response = await _supabase.rpc(
      'set_my_trip_preferences',
      params: {
        'p_origin_stop_id': originStopId,
        'p_destination_stop_id': destinationStopId,
      },
    );

    return PassengerTripPreferenceModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _supabase.rpc(
      'cancel_passenger_booking',
      params: {'p_booking_id': bookingId},
    );
  }

  @override
  Future<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async {
    await _supabase.rpc(
      'change_booking_seat',
      params: {'p_booking_id': bookingId, 'p_new_seat_id': newSeatId},
    );
  }

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _supabase.channel(
          'trip_seats_${tripId}_${identityHashCode(controller)}',
        );
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'trip_seat_state',
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

  @override
  Future<List<RoundTripReturnOptionModel>> getRoundTripReturnOptions({
    required String outboundTripId,
    required String outboundRouteStopId,
  }) async {
<<<<<<< HEAD
    if (kDebugMode) {
      debugPrint('ROUND_TRIP_DEBUG RPC request start');
    }
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    final response = await _supabase.rpc(
      'get_round_trip_return_options',
      params: {
        'p_outbound_trip_id': outboundTripId,
        'p_outbound_route_stop_id': outboundRouteStopId,
      },
    );

<<<<<<< HEAD
    if (kDebugMode) {
      debugPrint('ROUND_TRIP_DEBUG raw RPC response $response');
    }

    final list = response as List<dynamic>;
    final parsed = list
=======
    final list = response as List<dynamic>;
    return list
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
        .map(
          (e) => RoundTripReturnOptionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
<<<<<<< HEAD

    if (kDebugMode) {
      debugPrint('ROUND_TRIP_DEBUG parsed row count ${parsed.length}');
      debugPrint(
        'ROUND_TRIP_DEBUG parsed departure times ${parsed.map((e) => e.departureTime).toList()}',
      );
      debugPrint(
        'ROUND_TRIP_DEBUG parsed isBookable values ${parsed.map((e) => e.isBookable).toList()}',
      );
    }

    return parsed;
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
  }

  @override
  Future<RoundTripBundleHoldModel> createRoundTripBundleHold({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  }) async {
    final response = await _supabase.rpc(
      'create_round_trip_bundle_hold',
      params: {
        'p_outbound_trip_id': outboundTripId,
        'p_return_trip_id': returnTripId,
        'p_outbound_seat_id': outboundSeatId,
        'p_outbound_route_stop_id': outboundRouteStopId,
      },
    );

    return RoundTripBundleHoldModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<RoundTripBundleHoldModel> setRoundTripReturnSeat({
    required String bundleHoldId,
    required String returnSeatId,
  }) async {
    final response = await _supabase.rpc(
      'set_round_trip_return_seat',
      params: {
        'p_bundle_hold_id': bundleHoldId,
        'p_return_seat_id': returnSeatId,
      },
    );

    return RoundTripBundleHoldModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> releaseRoundTripBundleHold({
    required String bundleHoldId,
  }) async {
    await _supabase.rpc(
      'release_round_trip_bundle_hold',
      params: {'p_bundle_hold_id': bundleHoldId},
    );
  }

  @override
  Future<RoundTripConfirmationModel> confirmRoundTripBundle({
    required String bundleHoldId,
  }) async {
    final response = await _supabase.rpc(
      'confirm_round_trip_bundle',
      params: {'p_bundle_hold_id': bundleHoldId},
    );

    return RoundTripConfirmationModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<RoundTripBundleContextModel> getRoundTripBundleContext({
    required String bookingId,
  }) async {
    final response = await _supabase.rpc(
      'get_round_trip_bundle_context',
      params: {'p_booking_id': bookingId},
    );

    return RoundTripBundleContextModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Stream<void> subscribeToPassengerBookingUpdates() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return const Stream.empty();
    }

    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _supabase.channel(
          'passenger_bookings_${identityHashCode(controller)}',
        );
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
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
