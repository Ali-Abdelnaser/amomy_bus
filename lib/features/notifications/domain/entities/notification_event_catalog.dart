import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_notification.dart';

/// Notification event category aligning with passenger preferences.
enum NotificationCategory {
  serviceUpdates,
  bookingUpdates,
  walletUpdates,
  tripUpdates;

  String toDbKey() {
    switch (this) {
      case NotificationCategory.serviceUpdates:
        return 'service_updates';
      case NotificationCategory.bookingUpdates:
        return 'booking_updates';
      case NotificationCategory.walletUpdates:
        return 'wallet_updates';
      case NotificationCategory.tripUpdates:
        return 'trip_updates';
    }
  }

  String localizedName(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    switch (this) {
      case NotificationCategory.serviceUpdates:
        return isAr ? 'تحديثات الخدمة والإعلانات' : 'Service & System Updates';
      case NotificationCategory.bookingUpdates:
        return isAr ? 'تحديثات الحجز والتذاكر' : 'Booking & Ticket Updates';
      case NotificationCategory.walletUpdates:
        return isAr ? 'المحفظة وعمليات الشحن' : 'Wallet & Top-up Updates';
      case NotificationCategory.tripUpdates:
        return isAr ? 'تتبع الرحلة وموقع الأتوبيس' : 'Trip & Bus Tracking';
    }
  }
}

/// A single authoritative notification event definition in the AMOMY catalog.
class NotificationEventDefinition {
  final String eventType;
  final NotificationType type;
  final NotificationCategory category;
  final String titleAr;
  final String bodyAr;
  final String titleEn;
  final String bodyEn;
  final String destinationScreen;
  final Map<String, dynamic> samplePayload;
  final bool isPushOptional;
  final String dedupeStrategy;
  final IconData icon;
  final bool isAutomaticProductionEnabled;

  const NotificationEventDefinition({
    required this.eventType,
    required this.type,
    required this.category,
    required this.titleAr,
    required this.bodyAr,
    required this.titleEn,
    required this.bodyEn,
    required this.destinationScreen,
    required this.samplePayload,
    this.isPushOptional = true,
    required this.dedupeStrategy,
    required this.icon,
    this.isAutomaticProductionEnabled = true,
  });

  String localizedTitle(Locale locale) {
    return locale.languageCode == 'ar' ? titleAr : titleEn;
  }

  String localizedBody(Locale locale) {
    return locale.languageCode == 'ar' ? bodyAr : bodyEn;
  }
}

/// Authoritative Central Notification Event Catalog for AMOMY Bus.
///
/// Contains all 15 production/test events across the 4 core categories:
/// - service_updates (3)
/// - booking_updates (3)
/// - wallet_updates (4)
/// - trip_updates (5)
class NotificationEventCatalog {
  NotificationEventCatalog._();

  // ---------------------------------------------------------------------------
  // 1. GENERAL & SERVICE UPDATES (service_updates)
  // ---------------------------------------------------------------------------
  static const system = NotificationEventDefinition(
    eventType: 'system',
    type: NotificationType.system,
    category: NotificationCategory.serviceUpdates,
    titleAr: 'إشعار من عمومي',
    bodyAr: 'تحديثات وتنبيهات هامة تخص خدمة عمومي باص.',
    titleEn: 'AMOMY Notice',
    bodyEn: 'Important updates regarding AMOMY bus service.',
    destinationScreen: 'notifications',
    samplePayload: {'screen': 'notifications'},
    dedupeStrategy: 'none',
    icon: LucideIcons.bell,
  );

  static const generalAnnouncement = NotificationEventDefinition(
    eventType: 'general_announcement',
    type: NotificationType.generalAnnouncement,
    category: NotificationCategory.serviceUpdates,
    titleAr: 'إعلان عام',
    bodyAr: 'يسر عمومي إعلامكم بجداول ومواعيد التشغيل المحدثة.',
    titleEn: 'General Announcement',
    bodyEn: 'AMOMY is pleased to announce updated service schedules.',
    destinationScreen: 'home',
    samplePayload: {'screen': 'home'},
    dedupeStrategy: 'none',
    icon: LucideIcons.megaphone,
  );

  static const serviceUpdate = NotificationEventDefinition(
    eventType: 'service_update',
    type: NotificationType.serviceUpdate,
    category: NotificationCategory.serviceUpdates,
    titleAr: 'تحديث الخدمة',
    bodyAr: 'تم تحديث مسارات ومحطات التوقف لخدمة أفضل.',
    titleEn: 'Service Update',
    bodyEn: 'Routes and stops have been updated for better service.',
    destinationScreen: 'notifications',
    samplePayload: {'screen': 'notifications'},
    dedupeStrategy: 'none',
    icon: LucideIcons.info,
  );

  // ---------------------------------------------------------------------------
  // 2. BOOKING UPDATES (booking_updates)
  // ---------------------------------------------------------------------------
  static const bookingConfirmed = NotificationEventDefinition(
    eventType: 'booking_confirmed',
    type: NotificationType.bookingConfirmed,
    category: NotificationCategory.bookingUpdates,
    titleAr: 'تم تأكيد حجزك',
    bodyAr: 'تم تأكيد رحلتك الساعة 08:00 صباحاً والمقعد رقم 7.',
    titleEn: 'Booking confirmed',
    bodyEn: 'Your 08:00 AM trip is confirmed. Seat #7.',
    destinationScreen: 'ticket',
    samplePayload: {
      'screen': 'ticket',
      'booking_id': 'sample-booking-7',
      'time': '08:00',
      'seat': '7',
    },
    dedupeStrategy: 'booking_id',
    icon: LucideIcons.checkCircle2,
  );

  static const bookingCancelled = NotificationEventDefinition(
    eventType: 'booking_cancelled',
    type: NotificationType.bookingCancelled,
    category: NotificationCategory.bookingUpdates,
    titleAr: 'تم إلغاء الحجز',
    bodyAr: 'تم إلغاء حجز رحلتك بنجاح واسترداد النقاط إلى محفظتك.',
    titleEn: 'Booking cancelled',
    bodyEn: 'Your trip booking has been cancelled and points returned.',
    destinationScreen: 'trips',
    samplePayload: {
      'screen': 'trips',
      'booking_id': 'sample-booking-7',
    },
    dedupeStrategy: 'booking_id',
    icon: LucideIcons.xCircle,
  );

  static const seatChanged = NotificationEventDefinition(
    eventType: 'seat_changed',
    type: NotificationType.seatChanged,
    category: NotificationCategory.bookingUpdates,
    titleAr: 'تم تغيير المقعد',
    bodyAr: 'تم تغيير مقعدك إلى رقم 14 بنجاح.',
    titleEn: 'Seat updated',
    bodyEn: 'Your seat has been changed to #14.',
    destinationScreen: 'ticket',
    samplePayload: {
      'screen': 'ticket',
      'booking_id': 'sample-booking-7',
      'seat': '14',
    },
    dedupeStrategy: 'booking_id',
    icon: LucideIcons.armchair,
  );

  // ---------------------------------------------------------------------------
  // 3. WALLET & TOP-UP UPDATES (wallet_updates)
  // ---------------------------------------------------------------------------
  static const topupApproved = NotificationEventDefinition(
    eventType: 'topup_approved',
    type: NotificationType.topupApproved,
    category: NotificationCategory.walletUpdates,
    titleAr: 'تم قبول طلب الشحن',
    bodyAr: 'تم إضافة 300 نقطة إلى محفظتك بنجاح.',
    titleEn: 'Top-up approved',
    bodyEn: '300 points were added to your wallet.',
    destinationScreen: 'wallet',
    samplePayload: {
      'screen': 'wallet',
      'request_id': 'sample-topup-300',
      'points': '300',
    },
    dedupeStrategy: 'request_id',
    icon: LucideIcons.wallet,
  );

  static const topupRejected = NotificationEventDefinition(
    eventType: 'topup_rejected',
    type: NotificationType.topupRejected,
    category: NotificationCategory.walletUpdates,
    titleAr: 'لم يتم قبول طلب الشحن',
    bodyAr: 'راجع تفاصيل الطلب أو أعد المحاولة بإرفاق إيصال صالح.',
    titleEn: 'Top-up not approved',
    bodyEn: 'Please review your top-up request or submit a valid receipt.',
    destinationScreen: 'wallet',
    samplePayload: {
      'screen': 'wallet',
      'request_id': 'sample-topup-300',
    },
    dedupeStrategy: 'request_id',
    icon: LucideIcons.alertTriangle,
  );

  static const walletCredit = NotificationEventDefinition(
    eventType: 'wallet_credit',
    type: NotificationType.walletCredit,
    category: NotificationCategory.walletUpdates,
    titleAr: 'إضافة نقاط',
    bodyAr: 'تم إضافة 50 نقطة مكافأة إلى رصيدك.',
    titleEn: 'Points credited',
    bodyEn: '50 reward points were added to your balance.',
    destinationScreen: 'wallet',
    samplePayload: {
      'screen': 'wallet',
      'points': '50',
    },
    dedupeStrategy: 'none',
    icon: LucideIcons.coins,
  );

  static const walletRefund = NotificationEventDefinition(
    eventType: 'wallet_refund',
    type: NotificationType.walletRefund,
    category: NotificationCategory.walletUpdates,
    titleAr: 'تم استرداد النقاط',
    bodyAr: 'تمت إعادة 100 نقطة إلى محفظتك.',
    titleEn: 'Points refunded',
    bodyEn: '100 points were returned to your wallet.',
    destinationScreen: 'wallet',
    samplePayload: {
      'screen': 'wallet',
      'points': '100',
    },
    dedupeStrategy: 'none',
    icon: LucideIcons.rotateCcw,
  );

  // ---------------------------------------------------------------------------
  // 4. TRIP & TRACKING UPDATES (trip_updates)
  // ---------------------------------------------------------------------------
  static const busApproaching = NotificationEventDefinition(
    eventType: 'bus_approaching',
    type: NotificationType.busApproaching,
    category: NotificationCategory.tripUpdates,
    titleAr: 'الأتوبيس يقترب من محطتك',
    bodyAr: 'عمومي باص يقترب من محطة أحمد ماهر. استعد للركوب.',
    titleEn: 'Your bus is approaching',
    bodyEn: 'Your bus is approaching Ahmed Maher stop. Please get ready.',
    destinationScreen: 'live_map',
    samplePayload: {
      'screen': 'live_map',
      'stop_name': 'Ahmed Maher',
      'eta_minutes': '8',
    },
    dedupeStrategy: 'booking_run_approaching',
    icon: LucideIcons.bus,
  );

  static const busArrivedAtBoardingStop = NotificationEventDefinition(
    eventType: 'bus_arrived_at_boarding_stop',
    type: NotificationType.busArrivedAtBoardingStop,
    category: NotificationCategory.tripUpdates,
    titleAr: 'الأتوبيس وصل محطتك',
    bodyAr: 'الأتوبيس وصل الآن إلى محطة أحمد ماهر.',
    titleEn: 'Your bus has arrived',
    bodyEn: 'The bus has arrived at Ahmed Maher stop.',
    destinationScreen: 'live_map',
    samplePayload: {
      'screen': 'live_map',
      'stop_name': 'Ahmed Maher',
    },
    dedupeStrategy: 'booking_run_arrival',
    icon: LucideIcons.mapPin,
  );

  static const tripUpdate = NotificationEventDefinition(
    eventType: 'trip_update',
    type: NotificationType.tripUpdate,
    category: NotificationCategory.tripUpdates,
    titleAr: 'تحديث على الرحلة',
    bodyAr: 'الأوتوبيس يسير بانتظام في مسار الرحلة الحالي.',
    titleEn: 'Trip update',
    bodyEn: 'The bus is proceeding normally on its current route.',
    destinationScreen: 'live_map',
    samplePayload: {'screen': 'live_map'},
    dedupeStrategy: 'none',
    icon: LucideIcons.navigation,
  );

  static const tripDelayed = NotificationEventDefinition(
    eventType: 'trip_delayed',
    type: NotificationType.tripDelayed,
    category: NotificationCategory.tripUpdates,
    titleAr: 'تحديث على الرحلة',
    bodyAr: 'يوجد تأخير بسيط بسبب حركة المرور على مسار الرحلة.',
    titleEn: 'Trip update',
    bodyEn: 'Your current trip is slightly delayed due to traffic.',
    destinationScreen: 'live_map',
    samplePayload: {'screen': 'live_map'},
    dedupeStrategy: 'none',
    icon: LucideIcons.clock,
  );

  static const nextStopUpdate = NotificationEventDefinition(
    eventType: 'next_stop_update',
    type: NotificationType.nextStopUpdate,
    category: NotificationCategory.tripUpdates,
    titleAr: 'المحطة القادمة',
    bodyAr: 'المحطة القادمة هي جيهان.',
    titleEn: 'Next stop',
    bodyEn: 'The next stop is Jihan.',
    destinationScreen: 'live_map',
    samplePayload: {
      'screen': 'live_map',
      'next_stop': 'Jihan',
    },
    dedupeStrategy: 'none',
    icon: LucideIcons.arrowRightCircle,
    // Next stop update is available in Test Lab, but automatic production push
    // is deferred until on-board passenger presence verification is active.
    isAutomaticProductionEnabled: false,
  );

  /// All 15 supported events in logical grouping order.
  static const List<NotificationEventDefinition> allEvents = [
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
    busApproaching,
    busArrivedAtBoardingStop,
    tripUpdate,
    tripDelayed,
    nextStopUpdate,
  ];

  /// Lookup map by eventType.
  static final Map<String, NotificationEventDefinition> byType = {
    for (final event in allEvents) event.eventType: event,
  };

  /// Returns event definition or falls back to system.
  static NotificationEventDefinition find(String eventType) {
    return byType[eventType] ?? system;
  }
}
