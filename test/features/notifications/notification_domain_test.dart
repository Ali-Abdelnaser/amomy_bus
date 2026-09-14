import 'package:amomy_bus/features/notifications/data/models/notification_model.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_event_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationType', () {
    test('fromString parses all known types correctly', () {
      expect(NotificationType.fromString('system'), NotificationType.system);
      expect(NotificationType.fromString('general_announcement'), NotificationType.generalAnnouncement);
      expect(NotificationType.fromString('service_update'), NotificationType.serviceUpdate);
      expect(NotificationType.fromString('booking_confirmed'), NotificationType.bookingConfirmed);
      expect(NotificationType.fromString('booking_cancelled'), NotificationType.bookingCancelled);
      expect(NotificationType.fromString('seat_changed'), NotificationType.seatChanged);
      expect(NotificationType.fromString('topup_approved'), NotificationType.topupApproved);
      expect(NotificationType.fromString('topup_rejected'), NotificationType.topupRejected);
      expect(NotificationType.fromString('wallet_credit'), NotificationType.walletCredit);
      expect(NotificationType.fromString('wallet_refund'), NotificationType.walletRefund);
      expect(NotificationType.fromString('trip_update'), NotificationType.tripUpdate);
      expect(NotificationType.fromString('trip_delayed'), NotificationType.tripDelayed);
      expect(NotificationType.fromString('bus_approaching'), NotificationType.busApproaching);
      expect(NotificationType.fromString('approaching'), NotificationType.busApproaching);
      expect(NotificationType.fromString('bus_arrived_at_boarding_stop'), NotificationType.busArrivedAtBoardingStop);
      expect(NotificationType.fromString('bus_arrived'), NotificationType.busArrivedAtBoardingStop);
      expect(NotificationType.fromString('next_stop_update'), NotificationType.nextStopUpdate);
      expect(NotificationType.fromString('next_stop'), NotificationType.nextStopUpdate);
      expect(NotificationType.fromString('unknown_type'), NotificationType.unknown);
      expect(NotificationType.fromString(null), NotificationType.unknown);
    });

    test('toDbString returns accurate database strings', () {
      expect(NotificationType.system.toDbString(), 'system');
      expect(NotificationType.generalAnnouncement.toDbString(), 'general_announcement');
      expect(NotificationType.serviceUpdate.toDbString(), 'service_update');
      expect(NotificationType.bookingConfirmed.toDbString(), 'booking_confirmed');
      expect(NotificationType.bookingCancelled.toDbString(), 'booking_cancelled');
      expect(NotificationType.seatChanged.toDbString(), 'seat_changed');
      expect(NotificationType.topupApproved.toDbString(), 'topup_approved');
      expect(NotificationType.topupRejected.toDbString(), 'topup_rejected');
      expect(NotificationType.walletCredit.toDbString(), 'wallet_credit');
      expect(NotificationType.walletRefund.toDbString(), 'wallet_refund');
      expect(NotificationType.tripUpdate.toDbString(), 'trip_update');
      expect(NotificationType.tripDelayed.toDbString(), 'trip_delayed');
      expect(NotificationType.busApproaching.toDbString(), 'bus_approaching');
      expect(NotificationType.busArrivedAtBoardingStop.toDbString(), 'bus_arrived_at_boarding_stop');
      expect(NotificationType.nextStopUpdate.toDbString(), 'next_stop_update');
    });
  });

  group('NotificationEventCatalog Completeness', () {
    test('contains exactly 15 defined events across 4 core categories', () {
      expect(NotificationEventCatalog.allEvents.length, 15);

      final serviceEvents = NotificationEventCatalog.allEvents
          .where((e) => e.category == NotificationCategory.serviceUpdates)
          .toList();
      final bookingEvents = NotificationEventCatalog.allEvents
          .where((e) => e.category == NotificationCategory.bookingUpdates)
          .toList();
      final walletEvents = NotificationEventCatalog.allEvents
          .where((e) => e.category == NotificationCategory.walletUpdates)
          .toList();
      final tripEvents = NotificationEventCatalog.allEvents
          .where((e) => e.category == NotificationCategory.tripUpdates)
          .toList();

      expect(serviceEvents.length, 3);
      expect(bookingEvents.length, 3);
      expect(walletEvents.length, 4);
      expect(tripEvents.length, 5);
    });

    test('every catalog event has non-empty templates, valid destinations, and sample payloads', () {
      for (final event in NotificationEventCatalog.allEvents) {
        expect(event.eventType.isNotEmpty, isTrue, reason: 'Event type cannot be empty');
        expect(event.titleAr.isNotEmpty, isTrue, reason: '${event.eventType} missing titleAr');
        expect(event.bodyAr.isNotEmpty, isTrue, reason: '${event.eventType} missing bodyAr');
        expect(event.titleEn.isNotEmpty, isTrue, reason: '${event.eventType} missing titleEn');
        expect(event.bodyEn.isNotEmpty, isTrue, reason: '${event.eventType} missing bodyEn');
        expect(event.destinationScreen.isNotEmpty, isTrue, reason: '${event.eventType} missing destinationScreen');
        expect(event.samplePayload, isNotEmpty, reason: '${event.eventType} missing samplePayload');
        expect(event.dedupeStrategy.isNotEmpty, isTrue, reason: '${event.eventType} missing dedupeStrategy');
      }
    });

    test('find returns matched event or falls back to system', () {
      final confirmed = NotificationEventCatalog.find('booking_confirmed');
      expect(confirmed.eventType, 'booking_confirmed');
      expect(confirmed.category, NotificationCategory.bookingUpdates);

      final fallback = NotificationEventCatalog.find('non_existent_event');
      expect(fallback.eventType, 'system');
    });

    test('next_stop_update is marked with automatic production disabled', () {
      final nextStop = NotificationEventCatalog.find('next_stop_update');
      expect(nextStop.isAutomaticProductionEnabled, isFalse);
    });
  });

  group('AppNotification & NotificationModel', () {
    final now = DateTime(2026, 9, 14, 16, 0);

    final notification = NotificationModel(
      id: 'notif-123',
      userId: 'user-456',
      type: NotificationType.bookingConfirmed,
      titleAr: 'تم تأكيد الحجز',
      bodyAr: 'تم حجز مقعدك رقم 14 بنجاح.',
      titleEn: 'Booking Confirmed',
      bodyEn: 'Your seat #14 has been confirmed.',
      data: const {'booking_id': 'book-789', 'screen': 'ticket'},
      createdAt: now,
    );

    test('isRead returns false when readAt is null and true when populated', () {
      expect(notification.isRead, isFalse);

      final readNotif = notification.copyWith(readAt: DateTime.now());
      expect(readNotif.isRead, isTrue);
    });

    test('localizedTitle and localizedBody return correct locale strings', () {
      expect(notification.localizedTitle(const Locale('ar')), 'تم تأكيد الحجز');
      expect(notification.localizedBody(const Locale('ar')), 'تم حجز مقعدك رقم 14 بنجاح.');

      expect(notification.localizedTitle(const Locale('en')), 'Booking Confirmed');
      expect(notification.localizedBody(const Locale('en')), 'Your seat #14 has been confirmed.');
    });

    test('fromJson and toJson maintain full fidelity', () {
      final json = notification.toJson();
      expect(json['id'], 'notif-123');
      expect(json['type'], 'booking_confirmed');
      expect(json['title_ar'], 'تم تأكيد الحجز');
      expect(json['data']['booking_id'], 'book-789');

      final fromJson = NotificationModel.fromJson(json);
      expect(fromJson.id, notification.id);
      expect(fromJson.userId, notification.userId);
      expect(fromJson.type, notification.type);
      expect(fromJson.titleAr, notification.titleAr);
      expect(fromJson.titleEn, notification.titleEn);
      expect(fromJson.data['booking_id'], 'book-789');
    });

    test('fromJson handles empty or malformed fields safely', () {
      final safeModel = NotificationModel.fromJson(const {});
      expect(safeModel.id, '');
      expect(safeModel.userId, '');
      expect(safeModel.type, NotificationType.unknown);
      expect(safeModel.data, isEmpty);
      expect(safeModel.isRead, isFalse);
    });
  });
}
