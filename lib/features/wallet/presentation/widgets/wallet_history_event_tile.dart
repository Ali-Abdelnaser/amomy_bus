import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet_history_event.dart';

class WalletHistoryEventTile extends StatelessWidget {
  final WalletHistoryEvent event;

  const WalletHistoryEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(
      context,
    ).languageCode.startsWith('ar');
    final formatter = NumberFormat('#,###');

    final (title, subtitle, icon, iconBg, iconColor) =
        _resolveEventPresentation(event, l10n, isArabic);

    final signedAmount = event.signedAmount;
    final String amountText;
    final Color amountColor;

    if (signedAmount == null) {
      amountText = '—';
      amountColor = AppColors.textSecondary;
    } else if (signedAmount > 0) {
      amountText = '+${formatter.format(signedAmount)} ${l10n.ptsUnit}';
      amountColor = const Color(0xFF027A48); // Success Emerald Green
    } else if (signedAmount < 0) {
      amountText = '-${formatter.format(signedAmount.abs())} ${l10n.ptsUnit}';
      amountColor = AppColors.textPrimary; // Crisp primary text for debit
    } else {
      amountText = '0 ${l10n.ptsUnit}';
      amountColor = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Semantic Leading Icon Surface
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),

          // 2. Main Center Content: Title + Subtitle Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Right: Signed Points Amount
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              amountText,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: amountColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, IconData, Color, Color) _resolveEventPresentation(
    WalletHistoryEvent event,
    dynamic l10n,
    bool isArabic,
  ) {
    // 12-hour formatted time or date
    final timeFormat = DateFormat('h:mm a', isArabic ? 'ar' : 'en');
    final dateFormat = DateFormat('d MMM', isArabic ? 'ar' : 'en');
    final fullFormat = DateFormat('d MMM • h:mm a', isArabic ? 'ar' : 'en');

    final formattedCreatedAt = event.createdAt != null
        ? fullFormat.format(event.createdAt!.toLocal())
        : '';

    switch (event.semanticType) {
      case WalletSemanticType.tripBooking:
      case WalletSemanticType.extraSeat:
      case WalletSemanticType.refund:
        final title = _resolveTripTitle(event.semanticType, l10n);
        final subtitle = _buildTripSubtitle(
          event: event,
          isArabic: isArabic,
          dateFormat: dateFormat,
          timeFormat: timeFormat,
          fallbackDate: formattedCreatedAt,
          l10n: l10n,
        );
        final (icon, bg, color) = _resolveTripColors(event.semanticType);
        return (title, subtitle, icon, bg, color);

      case WalletSemanticType.pointsTopup:
        return (
          l10n.txTypePointsTopup,
          formattedCreatedAt,
          Icons.add_circle_outline_rounded,
          const Color(0xFFECFDF3),
          const Color(0xFF027A48),
        );

      case WalletSemanticType.extraPoints:
        return (
          l10n.txTypeExtraPoints,
          formattedCreatedAt,
          Icons.stars_rounded,
          const Color(0xFFFEF0C7),
          const Color(0xFFB54708),
        );

      case WalletSemanticType.subscriptionPoints:
        return (
          l10n.txTypeSubscriptionPoints,
          formattedCreatedAt,
          Icons.card_membership_rounded,
          const Color(0xFFEFF8FF),
          const Color(0xFF175CD3),
        );

      case WalletSemanticType.pointsExpired:
        return (
          l10n.txTypePointsExpired,
          formattedCreatedAt,
          Icons.alarm_off_rounded,
          const Color(0xFFFEF3F2),
          const Color(0xFFB42318),
        );

      case WalletSemanticType.balanceAdjustment:
        return (
          l10n.txTypeBalanceAdjustment,
          formattedCreatedAt,
          Icons.tune_rounded,
          const Color(0xFFF2F4F7),
          const Color(0xFF475467),
        );

      case WalletSemanticType.welcomeGift:
        return (
          l10n.txTypeWelcomeGift,
          formattedCreatedAt,
          Icons.card_giftcard_rounded,
          const Color(0xFFECFDF3),
          const Color(0xFF027A48),
        );

      case WalletSemanticType.campaignGift:
        return (
          l10n.txTypeCampaignGift,
          formattedCreatedAt,
          Icons.redeem_rounded,
          const Color(0xFFFEF0C7),
          const Color(0xFFB54708),
        );

      case WalletSemanticType.unknown:
        return (
          l10n.txTypeTransaction,
          formattedCreatedAt,
          Icons.receipt_long_rounded,
          const Color(0xFFF2F4F7),
          const Color(0xFF475467),
        );
    }
  }

  String _resolveTripTitle(WalletSemanticType type, dynamic l10n) {
    switch (type) {
      case WalletSemanticType.tripBooking:
        return l10n.txTypeTripBooking;
      case WalletSemanticType.extraSeat:
        return l10n.txTypeExtraSeat;
      case WalletSemanticType.refund:
        return l10n.txTypeRefund;
      default:
        return l10n.txTypeTrip;
    }
  }

  String _buildTripSubtitle({
    required WalletHistoryEvent event,
    required bool isArabic,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
    required String fallbackDate,
    required dynamic l10n,
  }) {
    final parts = <String>[];

    final dir = event.localizedTripDirection(isArabic);
    if (dir != null && dir.isNotEmpty) {
      parts.add(dir);
    }

    final targetDate = event.serviceDate ?? event.departureAt;
    if (targetDate != null) {
      parts.add(dateFormat.format(targetDate.toLocal()));
    }

    if (event.departureAt != null) {
      parts.add(timeFormat.format(event.departureAt!.toLocal()));
    }

    if (parts.isEmpty) {
      return fallbackDate;
    }

    // Optional seat suffix if available
    if (event.seatNumber != null && event.seatNumber!.trim().isNotEmpty) {
      final seatStr = l10n.seatNumberLabel(event.seatNumber!.trim());
      return '${parts.join(' • ')} • $seatStr';
    }

    return parts.join(' • ');
  }

  (IconData, Color, Color) _resolveTripColors(WalletSemanticType type) {
    switch (type) {
      case WalletSemanticType.tripBooking:
        return (
          Icons.directions_bus_rounded,
          const Color(0xFFE7F2FA),
          AppColors.primary,
        );
      case WalletSemanticType.extraSeat:
        return (
          Icons.event_seat_rounded,
          const Color(0xFFF0F9FF),
          const Color(0xFF026AA2),
        );
      case WalletSemanticType.refund:
        return (
          Icons.replay_rounded,
          const Color(0xFFF4F3FF),
          const Color(0xFF5925DC),
        );
      default:
        return (
          Icons.directions_bus_rounded,
          const Color(0xFFE7F2FA),
          AppColors.primary,
        );
    }
  }
}
