import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/point_transaction.dart';

class WalletTransactionTile extends StatelessWidget {
  final PointTransaction transaction;

  const WalletTransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat('#,###');

    // Date formatting (e.g., "13 Sep • 08:00" or "13 سبتمبر • 08:00")
    final dateFormat = DateFormat('d MMM • HH:mm', isArabic ? 'ar' : 'en');
    final formattedDate = dateFormat.format(transaction.createdAt.toLocal());

    // Resolve user-friendly category title, icon and color tone
    final (title, subtitle, icon, iconBg, iconColor) = _resolveTransactionStyle(
      transaction,
      l10n,
      formattedDate,
    );

    final isCredit = transaction.isCredit;
    final sign = isCredit ? '+' : '-';
    final pointsStr = '$sign${formatter.format(transaction.amount)} ${l10n.ptsUnit}';

    final amountColor = isCredit ? const Color(0xFF027A48) : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tinted leading icon surface (42x42)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),

          // 2. Center: Title and secondary date/metadata
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
            ),
          ),
          const SizedBox(width: 12),

          // 3. Right: Points change (+500 PTS / -30 PTS)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              pointsStr,
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

  (String, String, IconData, Color, Color) _resolveTransactionStyle(
    PointTransaction tx,
    dynamic l10n,
    String formattedDate,
  ) {
    final ref = (tx.referenceType ?? '').trim().toLowerCase();

    // Check if metadata contains route or stop details for trips
    final metaRoute = tx.metadata['route_name'] as String?;
    final metaBoarding = tx.metadata['boarding_stop'] as String?;
    final metaDropoff = tx.metadata['dropoff_stop'] as String?;

    // 1. Trip (reference_type = booking, trip, trip_booking, or debit with empty ref)
    if (ref == 'booking' || ref == 'trip' || ref == 'trip_booking' || (tx.isDebit && ref.isEmpty)) {
      String title = l10n.txTypeTrip;
      if (metaBoarding != null && metaDropoff != null) {
        title = '$metaBoarding → $metaDropoff';
      } else if (metaRoute != null && metaRoute.isNotEmpty) {
        title = metaRoute;
      }
      return (
        title,
        formattedDate,
        Icons.directions_bus_rounded,
        const Color(0xFFE7F2FA),
        AppColors.primary,
      );
    }

    // 2. Points Top-up (reference_type = topup, top_up, recharge)
    if (ref == 'topup' || ref == 'top_up' || ref.contains('topup') || ref == 'recharge') {
      return (
        l10n.txTypeTopUp,
        formattedDate,
        Icons.add_circle_outline_rounded,
        const Color(0xFFECFDF3),
        const Color(0xFF027A48),
      );
    }

    // 3. Booking Refund (reference_type = booking_cancellation, refund, cancellation)
    if (ref == 'booking_cancellation' || ref == 'refund' || ref == 'cancellation') {
      return (
        l10n.txTypeRefund,
        formattedDate,
        Icons.replay_rounded,
        const Color(0xFFF4F3FF),
        const Color(0xFF5925DC),
      );
    }

    // 4. Bonus (reference_type = bonus only)
    if (ref == 'bonus') {
      return (
        l10n.txTypeBonus,
        formattedDate,
        Icons.stars_rounded,
        const Color(0xFFFEF0C7),
        const Color(0xFFB54708),
      );
    }

    // 5. Gift (reference_type = gift only)
    if (ref == 'gift') {
      return (
        l10n.txTypeGift,
        formattedDate,
        Icons.card_giftcard_rounded,
        const Color(0xFFFCE8F3),
        const Color(0xFFC11574),
      );
    }

    // 6. Balance Adjustment (reference_type = admin_adjustment, manual_adjustment, adjustment)
    if (ref == 'admin_adjustment' || ref == 'manual_adjustment' || ref == 'adjustment') {
      return (
        l10n.txTypeAdjustment,
        formattedDate,
        Icons.tune_rounded,
        const Color(0xFFF2F4F7),
        const Color(0xFF475467),
      );
    }

    // 7. Unknown / Fallback: neutral "Points Adjustment" (NOT Bonus)
    return (
      l10n.txTypePointsAdjustment,
      formattedDate,
      Icons.tune_rounded,
      const Color(0xFFF2F4F7),
      const Color(0xFF475467),
    );
  }
}
