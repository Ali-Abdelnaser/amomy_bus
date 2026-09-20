import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Centralized status and business error localizer for Passenger UI.
class StatusLocalizer {
  const StatusLocalizer._();

  /// Formats raw or backend booking status to localized string.
  static String localizeBookingStatus(BuildContext context, String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return status;

    final normalized = status
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .trim();
    switch (normalized) {
      case 'confirmed':
      case 'bookingconfirmed':
      case 'scheduled':
        return l10n.bookingStatusConfirmed;
      case 'cancelled':
      case 'canceled':
        return l10n.bookingStatusCancelled;
      case 'completed':
      case 'departed':
        return l10n.bookingStatusCompleted;
      case 'finished':
        return l10n.bookingStatusFinished;
      case 'noshow':
        return l10n.bookingStatusNoShow;
      case 'pending':
        return l10n.bookingStatusPending;
      default:
        return status;
    }
  }

  /// Formats raw or backend tracking status to localized string.
  static String localizeTrackingStatus(BuildContext context, String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return status;

    final normalized = status
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .trim();
    switch (normalized) {
      case 'live':
      case 'online':
      case 'active':
        return l10n.trackingLive;
      case 'offline':
        return l10n.trackingOffline;
      case 'assignmentpending':
        return l10n.trackingAssignmentPending;
      case 'locationunavailable':
        return l10n.trackingLocationUnavailable;
      case 'progressionunavailable':
        return l10n.trackingProgressUnavailable;
      case 'tripnotactive':
        return l10n.trackingTripNotActive;
      case 'unavailable':
        return l10n.trackingUnavailable;
      default:
        return status;
    }
  }

  /// Formats raw or backend top-up / payment status.
  static String localizeTopUpStatus(BuildContext context, String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return status;

    final normalized = status
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .trim();
    switch (normalized) {
      case 'pending':
      case 'underreview':
        return l10n.statusPendingReview;
      case 'approved':
        return l10n.statusApproved;
      case 'rejected':
        return l10n.statusRejected;
      case 'awaitingpayment':
        return l10n.statusAwaitingPayment;
      default:
        return status;
    }
  }

  /// Formats transaction types.
  static String localizeTransactionType(BuildContext context, String? txType) {
    if (txType == null || txType.trim().isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return txType;

    final normalized = txType
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .trim();
    switch (normalized) {
      case 'tripbooking':
      case 'trip':
      case 'booking':
        return l10n.txTypeTripBooking;
      case 'extraseat':
        return l10n.txTypeExtraSeat;
      case 'refund':
        return l10n.txTypeRefund;
      case 'topup':
      case 'pointstopup':
      case 'topuprequest':
        return l10n.txTypePointsTopup;
      case 'extrapoints':
        return l10n.txTypeExtraPoints;
      case 'subscriptionpoints':
      case 'subscription':
        return l10n.txTypeSubscriptionPoints;
      case 'pointsexpired':
      case 'expired':
        return l10n.txTypePointsExpired;
      case 'bonus':
        return l10n.txTypeBonus;
      case 'gift':
        return l10n.txTypeGift;
      case 'balanceadjustment':
      case 'pointsadjustment':
      case 'manualadjustment':
      case 'adjustment':
        return l10n.txTypeBalanceAdjustment;
      default:
        return l10n.txTypeTransaction;
    }
  }

  /// Localizes trip direction labels (Outbound -> ذهاب / Return -> عودة).
  static String localizeDirection(BuildContext context, String? direction) {
    if (direction == null || direction.trim().isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return direction;

    final lower = direction.toLowerCase().trim();
    if (lower == 'outbound' || lower == 'ذهاب') {
      return l10n.directionOutbound;
    } else if (lower == 'return' || lower == 'عودة') {
      return l10n.directionReturn;
    }
    return direction;
  }

  /// Maps known backend business error codes / exception messages to user-friendly localized text.
  static String localizeError(BuildContext context, String? rawError) {
    if (rawError == null || rawError.trim().isEmpty) {
      return AppLocalizations.of(context)?.errorOccurred ??
          'An error occurred.';
    }
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return rawError;

    final errUpper = rawError.toUpperCase();

    if (errUpper.contains('ROUND_TRIP_MUST_START_WITH_OUTBOUND')) {
      return l10n.errorRoundTripMustStartWithOutbound;
    }
    if (errUpper.contains('INVALID_ROUND_TRIP_DIRECTIONS')) {
      return l10n.errorInvalidRoundTripDirections;
    }
    if (errUpper.contains('ROUND_TRIP_SAME_DAY_REQUIRED')) {
      return l10n.errorRoundTripSameDayRequired;
    }
    if (errUpper.contains('RETURN_MUST_BE_AFTER_OUTBOUND')) {
      return l10n.errorReturnMustBeAfterOutbound;
    }
    if (errUpper.contains('ROUND_TRIP_DISCOUNT_ALREADY_USED_TODAY')) {
      return l10n.errorRoundTripDiscountAlreadyUsedToday;
    }
    if (errUpper.contains('ROUND_TRIP_REQUIRES_UNBOOKED_TRIPS')) {
      return l10n.errorRoundTripRequiresUnbookedTrips;
    }
    if (errUpper.contains('ROUND_TRIP_HOLD_ALREADY_ACTIVE')) {
      return l10n.errorRoundTripHoldAlreadyActive;
    }
    if (errUpper.contains('ROUND_TRIP_HOLD_NOT_FOUND')) {
      return l10n.errorRoundTripHoldNotFound;
    }
    if (errUpper.contains('ROUND_TRIP_HOLD_INVALID')) {
      return l10n.errorRoundTripHoldInvalid;
    }
    if (errUpper.contains('RETURN_SEAT_REQUIRED')) {
      return l10n.errorReturnSeatRequired;
    }
    if (errUpper.contains('ROUND_TRIP_CANCELLATION_WINDOW_CLOSED')) {
      return l10n.errorRoundTripCancellationWindowClosed;
    }
    if (errUpper.contains('ROUND_TRIP_ALREADY_USED')) {
      return l10n.errorRoundTripAlreadyUsed;
    }
    if (errUpper.contains('ROUND_TRIP_BUNDLE_NOT_CANCELLABLE')) {
      return l10n.errorRoundTripBundleNotCancellable;
    }

    if (errUpper.contains('HOLD_EXPIRED') ||
        errUpper.contains('HOLD EXPIRED')) {
      return l10n.errorHoldExpired;
    }
    if (errUpper.contains('BOOKING_CLOSED') ||
        errUpper.contains('BOOKING CLOSED')) {
      return l10n.errorBookingClosed;
    }
    if (errUpper.contains('CANCELLATION_WINDOW_CLOSED') ||
        errUpper.contains('CANCELLATION CLOSED')) {
      return l10n.errorCancellationWindowClosed;
    }
    if (errUpper.contains('CHANGE_SEAT_WINDOW_CLOSED') ||
        errUpper.contains('CHANGE SEAT CLOSED')) {
      return l10n.errorChangeSeatWindowClosed;
    }
    if (errUpper.contains('SERVICE_DAY_OFF')) {
      return l10n.errorServiceDayOff;
    }
    if (errUpper.contains('SEAT_UNAVAILABLE') ||
        errUpper.contains('SEAT ALREADY HELD') ||
        errUpper.contains('SEAT_ALREADY_BOOKED') ||
        errUpper.contains('SEAT_HELD')) {
      return l10n.seatUnavailableNotice;
    }
    if (errUpper.contains('INSUFFICIENT_POINTS') ||
        errUpper.contains('INSUFFICIENT_BALANCE')) {
      return l10n.insufficientPointsNotice;
    }
    if (errUpper.contains('ALREADY_BOOKED_TRIP') ||
        errUpper.contains('ALREADY_BOOKED')) {
      return l10n.alreadyBookedTrip;
    }
    if (errUpper.contains('OUTBOUND_TRIP_UNAVAILABLE') ||
        errUpper.contains('RETURN_TRIP_UNAVAILABLE') ||
        errUpper.contains('TRIP_UNAVAILABLE')) {
      return l10n.errorBookingClosed;
    }

    // Do NOT leak raw SQL, Postgres, RPC or snake_case errors
    if (rawError.contains('PostgrestException') ||
        rawError.contains('RPC') ||
        rawError.contains('pg_') ||
        rawError.contains('sql') ||
        rawError.contains('DatabaseException') ||
        rawError.contains('SocketException')) {
      return l10n.errorOccurred;
    }

    return l10n.errorOccurred;
  }
}
