import 'dart:ui';
import 'package:equatable/equatable.dart';

enum NotificationType {
  system,
  generalAnnouncement,
  serviceUpdate,
  bookingConfirmed,
  bookingCancelled,
  seatChanged,
  topupApproved,
  topupRejected,
  walletCredit,
  walletRefund,
  tripUpdate,
  tripDelayed,
  busApproaching,
  busArrivedAtBoardingStop,
  nextStopUpdate,
  unknown;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'system':
        return NotificationType.system;
      case 'general_announcement':
        return NotificationType.generalAnnouncement;
      case 'service_update':
        return NotificationType.serviceUpdate;
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'seat_changed':
        return NotificationType.seatChanged;
      case 'topup_approved':
        return NotificationType.topupApproved;
      case 'topup_rejected':
        return NotificationType.topupRejected;
      case 'wallet_credit':
        return NotificationType.walletCredit;
      case 'wallet_refund':
        return NotificationType.walletRefund;
      case 'trip_update':
        return NotificationType.tripUpdate;
      case 'trip_delayed':
        return NotificationType.tripDelayed;
      case 'bus_approaching':
      case 'approaching':
        return NotificationType.busApproaching;
      case 'bus_arrived_at_boarding_stop':
      case 'bus_arrived':
        return NotificationType.busArrivedAtBoardingStop;
      case 'next_stop_update':
      case 'next_stop':
        return NotificationType.nextStopUpdate;
      default:
        return NotificationType.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationType.system:
        return 'system';
      case NotificationType.generalAnnouncement:
        return 'general_announcement';
      case NotificationType.serviceUpdate:
        return 'service_update';
      case NotificationType.bookingConfirmed:
        return 'booking_confirmed';
      case NotificationType.bookingCancelled:
        return 'booking_cancelled';
      case NotificationType.seatChanged:
        return 'seat_changed';
      case NotificationType.topupApproved:
        return 'topup_approved';
      case NotificationType.topupRejected:
        return 'topup_rejected';
      case NotificationType.walletCredit:
        return 'wallet_credit';
      case NotificationType.walletRefund:
        return 'wallet_refund';
      case NotificationType.tripUpdate:
        return 'trip_update';
      case NotificationType.tripDelayed:
        return 'trip_delayed';
      case NotificationType.busApproaching:
        return 'bus_approaching';
      case NotificationType.busArrivedAtBoardingStop:
        return 'bus_arrived_at_boarding_stop';
      case NotificationType.nextStopUpdate:
        return 'next_stop_update';
      case NotificationType.unknown:
        return 'system';
    }
  }
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String titleAr;
  final String bodyAr;
  final String titleEn;
  final String bodyEn;
  final Map<String, dynamic> data;
  final String? entityType;
  final String? entityId;
  final String? dedupeKey;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleAr,
    required this.bodyAr,
    required this.titleEn,
    required this.bodyEn,
    this.data = const {},
    this.entityType,
    this.entityId,
    this.dedupeKey,
    this.readAt,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isRead => readAt != null;

  String localizedTitle(Locale locale) {
    if (locale.languageCode == 'ar') {
      return titleAr.isNotEmpty ? titleAr : titleEn;
    }
    return titleEn.isNotEmpty ? titleEn : titleAr;
  }

  String localizedBody(Locale locale) {
    if (locale.languageCode == 'ar') {
      return bodyAr.isNotEmpty ? bodyAr : bodyEn;
    }
    return bodyEn.isNotEmpty ? bodyEn : bodyAr;
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? titleAr,
    String? bodyAr,
    String? titleEn,
    String? bodyEn,
    Map<String, dynamic>? data,
    String? entityType,
    String? entityId,
    String? dedupeKey,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      titleAr: titleAr ?? this.titleAr,
      bodyAr: bodyAr ?? this.bodyAr,
      titleEn: titleEn ?? this.titleEn,
      bodyEn: bodyEn ?? this.bodyEn,
      data: data ?? this.data,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        titleAr,
        bodyAr,
        titleEn,
        bodyEn,
        data,
        entityType,
        entityId,
        dedupeKey,
        readAt,
        createdAt,
        expiresAt,
      ];
}
