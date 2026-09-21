import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../shell/presentation/widgets/nav_svg_icon.dart';
import 'trip_ticket_svg_background.dart';

/// Premium digital transport ticket for historical trips.
/// Reuses the exact SVG ticket geometry ([TripTicketSvgBackground]) and divider ratio (25.12% / 74.88%).
/// In the large zone, a dedicated date panel replaces the action buttons.
class TripHistoryCard extends StatelessWidget {
  final PassengerBooking booking;
  final int animationIndex;

  const TripHistoryCard({
    super.key,
    required this.booking,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final isFinished =
        booking.checkedInAt != null ||
        booking.status.toLowerCase() == 'finished';

    // Status colors and background styling
    final (
      statusLabel,
      statusColor,
      statusBg,
      statusBorder,
      cardBg,
      cardBorder,
      shadowColor,
    ) = switch (booking.status.toLowerCase()) {
      _ when isFinished => (
        isAr ? 'منتهية' : 'Finished',
        const Color(0xFF64748B),
        const Color(0xFFF1F5F9),
        const Color(0xFFE2E8F0),
        const Color(0xFFF8FAFC),
        const Color(0xFFE2E8F0),
        Colors.black.withValues(alpha: 0.03),
      ),
      'completed' => (
        isAr ? 'مكتملة' : 'Completed',
        AppColors.success,
        AppColors.successLight,
        AppColors.success.withValues(alpha: 0.25),
        const Color(0xFFF4FDF7),
        AppColors.success.withValues(alpha: 0.35),
        AppColors.success.withValues(alpha: 0.07),
      ),
      'cancelled' => (
        isAr ? 'ملغاة' : 'Cancelled',
        AppColors.error,
        AppColors.errorLight,
        AppColors.error.withValues(alpha: 0.25),
        const Color(0xFFFFF7F7),
        AppColors.error.withValues(alpha: 0.35),
        AppColors.error.withValues(alpha: 0.06),
      ),
      'no_show' => (
        isAr ? 'لم يحضر' : 'No-show',
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
        const Color(0xFFF59E0B).withValues(alpha: 0.30),
        const Color(0xFFFFFBEB),
        const Color(0xFFF59E0B).withValues(alpha: 0.35),
        const Color(0xFFF59E0B).withValues(alpha: 0.06),
      ),
      _ => (
        isAr ? 'تمت الرحلة' : 'Finished',
        const Color(0xFF64748B),
        const Color(0xFFF1F5F9),
        const Color(0xFFE2E8F0),
        const Color(0xFFF8FAFC),
        const Color(0xFFE2E8F0),
        Colors.black.withValues(alpha: 0.03),
      ),
    };

    // Formatted date string (e.g., "12 September 2026" / "12 سبتمبر 2026")
    final formattedDate = DateFormat(
      'd MMMM yyyy',
      isAr ? 'ar' : 'en',
    ).format(booking.serviceDate);

    // Stop names
    final displayOrigin = booking.originName(locale);
    final displayDest = booking.destinationName(locale);

    const cardHeight = 144.0;

    Widget cardWidget = SizedBox(
      height: cardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final smallZoneWidth =
              totalWidth * TripTicketSvgBackground.dividerRatio;
          final largeZoneWidth = totalWidth - smallZoneWidth;

          return Stack(
            children: [
              // 1. Real Ticket SVG Background Base
              Positioned.fill(
                child: TripTicketSvgBackground(
                  fillColor: cardBg,
                  borderColor: cardBorder,
                  borderWidth: 1.0,
                  shadowColor: shadowColor,
                  elevation: 2.5,
                  flipX: isAr,
                ),
              ),

              // 2. Strict Two-Zone Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================
                  // SMALL STUB ZONE (25.12%):
                  // 1. Status (Top)
                  // 2. Time (with static dot & dark text)
                  // 3. Seat (with Nav Trips SVG & dark text)
                  // 4. Fare (with Nav Wallet SVG & dark text)
                  // ==========================================
                  SizedBox(
                    width: smallZoneWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isAr ? 10 : 6,
                        8,
                        isAr ? 6 : 10,
                        8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                            ),
                          ),

                          // 2. TIME ROW WITH STATIC STATE-COLORED DOT
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppTimeFormatter.formatPassengerBooking(
                                    booking,
                                    isArabic: isAr,
                                  ),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: const Color(0xFF101828),
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // 3. SEAT ROW (Trip SVG + Dark text)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NavSvgIcon(
                                type: NavSvgType.trip,
                                color: statusColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'المقعد' : 'Seat',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475467),
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    booking.seatNumber.isNotEmpty
                                        ? booking.seatNumber
                                        : '—',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF101828),
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // 4. FARE ROW (Wallet SVG + Dark text)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NavSvgIcon(
                                type: NavSvgType.wallet,
                                color: statusColor,
                                size: 13,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                '${booking.farePoints.toInt()}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isAr ? 'نقطة' : 'pts',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475467),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==========================================
                  // LARGE MAIN ZONE (74.88%):
                  // 1. From → To Route Visual (Upper zone)
                  // 2. Date Strip (Lower zone replacing action buttons)
                  // ==========================================
                  SizedBox(
                    width: largeZoneWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isAr ? 12 : 14,
                        12,
                        isAr ? 14 : 12,
                        12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. FROM / TO VERTICAL ROUTE COMPOSITION
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ROW 1: ORIGIN STOP
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.22,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.my_location_rounded,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'من: ' : 'From: ',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475467),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        displayOrigin,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: const Color(0xFF101828),
                                              letterSpacing: -0.2,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // VERTICAL ROUTE CONNECTOR
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 11.0,
                                  ),
                                  child: _HistoryVerticalConnector(
                                    height: 7,
                                    color: statusColor,
                                  ),
                                ),
                                AppSpacing.gapH8,

                                // ROW 2: DESTINATION STOP
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFD49B00,
                                        ).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(
                                            0xFFD49B00,
                                          ).withValues(alpha: 0.25),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFFD49B00),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'إلى: ' : 'To: ',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475467),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        displayDest,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: const Color(0xFF101828),
                                              letterSpacing: -0.2,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 2. DATE STRIP (Replacing action buttons area)
                          Container(
                            height: 36,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  AppIcons.calendar,
                                  size: 15,
                                  color: Color(0xFF01589F),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFF101828),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Staggered entrance animation
    if (!disableAnimations) {
      final staggerDelay = (animationIndex * 45).clamp(0, 180);
      cardWidget = cardWidget
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: staggerDelay),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .slideY(
            begin: 0.08,
            end: 0,
            delay: Duration(milliseconds: staggerDelay),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
    }

    return cardWidget;
  }
}

/// Vertical dashed transit route connector connecting the From pin to the To pin.
class _HistoryVerticalConnector extends StatelessWidget {
  final double height;
  final Color color;

  const _HistoryVerticalConnector({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(
        size: Size(2, height),
        painter: _HistoryDashedPainter(color: color.withValues(alpha: 0.55)),
      ),
    );
  }
}

class _HistoryDashedPainter extends CustomPainter {
  final Color color;

  const _HistoryDashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashHeight = 2.8;
    const dashSpace = 2.4;
    double startY = 0;

    final x = size.width / 2;
    while (startY < size.height) {
      final endY = (startY + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryDashedPainter oldDelegate) =>
      oldDelegate.color != color;
}
