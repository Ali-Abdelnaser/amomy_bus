import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../error/app_error_mapper.dart';

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
      case 'checkedin':
      case 'boarded':
        return Localizations.localeOf(context).languageCode.startsWith('ar')
            ? 'منتهية'
            : l10n.bookingStatusFinished;
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
  static String localizeError(BuildContext context, dynamic rawError) {
    return AppErrorMapper.map(context, rawError);
  }
}
