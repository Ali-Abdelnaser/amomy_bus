import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/app_notification.dart';
import '../services/notification_router.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onMarkRead;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onMarkRead,
  });

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
      case NotificationType.seatChanged:
        return AppIcons.ticket;
      case NotificationType.topupApproved:
      case NotificationType.topupRejected:
      case NotificationType.walletCredit:
      case NotificationType.walletRefund:
        return AppIcons.wallet;
      case NotificationType.busApproaching:
      case NotificationType.tripUpdate:
      case NotificationType.tripDelayed:
      case NotificationType.busArrivedAtBoardingStop:
      case NotificationType.nextStopUpdate:
        return AppIcons.bus;
      case NotificationType.system:
      case NotificationType.unknown:
      case NotificationType.generalAnnouncement:
      case NotificationType.serviceUpdate:
        return AppIcons.notification;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.topupApproved:
      case NotificationType.walletCredit:
      case NotificationType.busArrivedAtBoardingStop:
        return AppColors.success;
      case NotificationType.bookingCancelled:
      case NotificationType.topupRejected:
        return AppColors.error;
      case NotificationType.busApproaching:
      case NotificationType.tripDelayed:
        return AppColors.warning;
      case NotificationType.seatChanged:
      case NotificationType.walletRefund:
      case NotificationType.tripUpdate:
      case NotificationType.nextStopUpdate:
      case NotificationType.system:
      case NotificationType.generalAnnouncement:
      case NotificationType.serviceUpdate:
      case NotificationType.unknown:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime dt, Locale locale) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return locale.languageCode == 'ar' ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return locale.languageCode == 'ar' ? 'منذ $mins دقيقة' : '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return locale.languageCode == 'ar' ? 'منذ $hours ساعة' : '${hours}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return locale.languageCode == 'ar' ? 'منذ $days يوم' : '${days}d ago';
    } else {
      return DateFormat.yMMMd(locale.languageCode).format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final title = notification.localizedTitle(locale);
    final body = notification.localizedBody(locale);
    final timeStr = _formatDate(notification.createdAt, locale);
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? AppColors.primary.withAlpha(12) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isUnread) {
            onMarkRead?.call();
          }
          NotificationRouter.navigateToDestination(notification.data);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? AppColors.primary.withAlpha(50) : AppColors.border,
              width: isUnread ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIconColor(notification.type).withAlpha(24),
                ),
                child: Icon(
                  _getIconForType(notification.type),
                  size: 20,
                  color: _getIconColor(notification.type),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Body, Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
