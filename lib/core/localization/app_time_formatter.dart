import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/booking/domain/entities/booking_entities.dart';
import '../../features/home/domain/entities/home_summary.dart';

/// Single authoritative 12-hour time formatter for passenger-visible trip times.
///
/// Ensures consistent localized 12-hour formatting across the entire passenger app:
/// - English: "8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"
/// - Arabic: "8:00 ص", "9:00 ص", "10:00 ص", "11:00 ص", "1:00 م", "2:00 م", "3:00 م", "4:00 م"
///
/// Prevents raw 24-hour timestamps (13:00, 14:00, 15:00, 16:00) from ever showing to passengers.
class AppTimeFormatter {
  const AppTimeFormatter._();

  static const String serviceTimeZoneName = 'Africa/Cairo';
  static bool _timeZonesInitialized = false;
  static tz.Location? _cairoLocation;

  static void _ensureTimeZonesInitialized() {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }
  }

  static DateTime cairoServiceTime(DateTime instant) {
    if (!instant.isUtc) {
      return instant;
    }

    _ensureTimeZonesInitialized();
    final location = _cairoLocation ??= tz.getLocation(serviceTimeZoneName);
    return tz.TZDateTime.from(instant, location);
  }

  /// Canonical 12-hour formatter.
  /// Prefers structured [departureAt] DateTime over backend preformatted [departureTime] string.
  static String formatDepartureTime({
    DateTime? departureAt,
    String? departureTime,
    String? locale,
    bool isArabic = false,
  }) {
    final isAr = isArabic || (locale != null && locale.startsWith('ar'));

    int? hour;
    int? minute;

    if (departureAt != null) {
      final serviceTime = cairoServiceTime(departureAt);
      hour = serviceTime.hour;
      minute = serviceTime.minute;
    } else if (departureTime != null && departureTime.trim().isNotEmpty) {
      final parts = departureTime.trim().split(':');
      if (parts.isNotEmpty) {
        hour = int.tryParse(parts[0]);
      }
      if (parts.length > 1) {
        final minPart = parts[1].split(' ').first;
        minute = int.tryParse(minPart);
      }
    }

    if (hour == null) {
      return departureTime ?? '';
    }

    minute ??= 0;

    final isPm = hour >= 12;
    int displayHour = hour % 12;
    if (displayHour == 0) {
      displayHour = 12;
    }

    final displayMinute = minute.toString().padLeft(2, '0');
    final period = isPm ? (isAr ? 'م' : 'PM') : (isAr ? 'ص' : 'AM');

    return '$displayHour:$displayMinute $period';
  }

  /// Convenience formatter for [BuildContext].
  static String formatWithContext(
    BuildContext context, {
    DateTime? departureAt,
    String? departureTime,
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    return formatDepartureTime(
      departureAt: departureAt,
      departureTime: departureTime,
      locale: locale,
    );
  }

  /// Formats a [TripOption].
  static String formatTripOption(
    TripOption trip, {
    String? locale,
    bool isArabic = false,
  }) {
    return formatDepartureTime(
      departureAt: trip.departureAt,
      departureTime: trip.departureTime,
      locale: locale,
      isArabic: isArabic,
    );
  }

  /// Formats a [PassengerTodayTrip].
  static String formatPassengerTodayTrip(
    PassengerTodayTrip trip, {
    String? locale,
    bool isArabic = false,
  }) {
    return formatDepartureTime(
      departureAt: trip.departureAt,
      departureTime: trip.departureTime,
      locale: locale,
      isArabic: isArabic,
    );
  }

  /// Formats a [PassengerUpcomingTrip].
  static String formatUpcomingTrip(
    PassengerUpcomingTrip trip, {
    String? locale,
    bool isArabic = false,
  }) {
    return formatDepartureTime(
      departureAt: trip.departureAt,
      departureTime: trip.departureTime,
      locale: locale,
      isArabic: isArabic,
    );
  }

  /// Formats a [PassengerBooking].
  static String formatPassengerBooking(
    PassengerBooking booking, {
    String? locale,
    bool isArabic = false,
  }) {
    return formatDepartureTime(
      departureAt: booking.departureAt,
      departureTime: booking.departureTime,
      locale: locale,
      isArabic: isArabic,
    );
  }
}
