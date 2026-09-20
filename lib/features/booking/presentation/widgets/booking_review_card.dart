import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../shell/presentation/widgets/nav_svg_icon.dart';
import '../../domain/entities/booking_entities.dart';

/// Redesigned Premium AMOMY Review Booking Screen.
///
/// Visual Architecture:
/// 1. Surface A: Premium Journey Card
///    - Direction pill (pale blue / warm amber) + Hero departure time (28px bold)
///    - Subtle Date placement
///    - Elegant compact vertical journey path (AMOMY blue dot -> gold dot)
///    - Bottom metadata row: Authentic coach bus seat badge + fare tag
/// 2. Hold Countdown Chip: Compact, lightweight soft amber pill
/// 3. Surface B: Fare / Balance Panel (Compact, no redundant table)
///    - TOTAL: 20 Points (Hero emphasis)
///    - Available balance & Balance after booking (clean numeric typography)
/// 4. Reassurance shield note
/// 5. Full-width Confirm CTA with loading and expiry protection
class BookingReviewCard extends StatefulWidget {
  final TripOption trip;
  final TripSeat seat;
  final RouteStop? routeStop;
  final RouteStop? destinationRouteStop;
  final RoundTripBundleHold? bundleHold;
  final TripSeat? returnSeat;
  final RoundTripReturnOption? returnOption;
  final double userAvailablePoints;
  final VoidCallback onConfirm;
  final VoidCallback? onChooseSeatAgain;
  final bool isConfirming;
  final int? initialHoldSecondsRemaining;

  const BookingReviewCard({
    super.key,
    required this.trip,
    required this.seat,
    this.routeStop,
    this.destinationRouteStop,
    this.bundleHold,
    this.returnSeat,
    this.returnOption,
    required this.userAvailablePoints,
    required this.onConfirm,
    this.onChooseSeatAgain,
    this.isConfirming = false,
    this.initialHoldSecondsRemaining,
  });

  @override
  State<BookingReviewCard> createState() => _BookingReviewCardState();
}

class _BookingReviewCardState extends State<BookingReviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;
  late final Animation<double> _countdownFadeAnim;
  late final Animation<double> _fareFadeAnim;
  late final Animation<double> _ctaFadeAnim;

  int get _secondsRemaining {
    if (widget.initialHoldSecondsRemaining != null) {
      return widget.initialHoldSecondsRemaining!;
    }
    if (widget.bundleHold != null) {
      return widget.bundleHold!.remainingSeconds;
    }
    if (widget.seat.heldExpiresAt != null) {
      final diff = widget.seat.heldExpiresAt!
          .toUtc()
          .difference(DateTime.now().toUtc())
          .inSeconds;
      return diff > 0 ? diff : 0;
    }
    return 0;
  }

  bool get _isExpired =>
      _secondsRemaining <= 0 &&
      (widget.initialHoldSecondsRemaining != null ||
          widget.bundleHold != null ||
          widget.seat.heldExpiresAt != null);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Staggered entrance animations (total ~320ms, restrained & calm)
    _cardFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _cardSlideAnim =
        Tween<Offset>(
          begin: const Offset(0.0, 0.035),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _countdownFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );

    _fareFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );

    _ctaFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static String _formatInformationalDate(DateTime date, bool isAr) {
    const arMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day;
    final month = isAr ? arMonths[date.month - 1] : enMonths[date.month - 1];
    final prefix = isAr ? 'اليوم' : 'Today';
    return '$prefix · $day $month';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');

    final isBundle = widget.bundleHold != null;
    final totalFare = isBundle
        ? widget.bundleHold!.totalPoints
        : (widget.routeStop?.farePoints ?? widget.trip.farePoints);

    final hasEnoughPoints = widget.userAvailablePoints >= totalFare;
    final balanceAfterBooking = (widget.userAvailablePoints - totalFare).clamp(
      0,
      double.infinity,
    );
    final deficitPoints = (totalFare - widget.userAvailablePoints).ceil();
    final todayStr = _formatInformationalDate(DateTime.now(), isAr);

    final isOutbound = widget.trip.direction == BookingDirection.outbound;
    final isConfirmEnabled =
        hasEnoughPoints && !_isExpired && !widget.isConfirming;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // 1. SURFACE A: JOURNEY CARD(S)
    Widget journeyCard;
    if (isBundle) {
      final bundle = widget.bundleHold!;
      final returnSeatNumber = widget.returnSeat?.seatNumber ?? '—';
      final returnDepartureTime = widget.returnOption != null
          ? AppTimeFormatter.formatDepartureTime(
              departureAt: widget.returnOption!.departureAt,
              departureTime: widget.returnOption!.departureTime,
              isArabic: isAr,
            )
          : (isAr ? 'العودة' : 'Return');

      journeyCard = Column(
        children: [
          // OUTBOUND LEG CARD
          _SingleLegCard(
            isOutbound: true,
            titleLabel: l10n.directionOutbound,
            dateStr: todayStr,
            departureTime: AppTimeFormatter.formatTripOption(
              widget.trip,
              isArabic: isAr,
            ),
            timeLabel: l10n.tripDetailsTime,
            originName:
                widget.routeStop?.stopName(locale) ??
                widget.trip.originName(locale),
            originLocality: widget.routeStop?.locality(locale),
            destinationName:
                widget.destinationRouteStop?.stopName(locale) ??
                widget.trip.destinationName(locale),
            destinationLocality: widget.destinationRouteStop?.locality(locale),
            seatNumber: widget.seat.seatNumber,
            seatLabel: l10n.tripDetailsSeat,
            fareLabel:
                '${bundle.outboundBaseFarePoints.toInt()} ${l10n.pointsUnit}',
            isAr: isAr,
          ),
          const SizedBox(height: 12),
          // RETURN LEG CARD
          _SingleLegCard(
            isOutbound: false,
            titleLabel: l10n.directionReturn,
            dateStr: todayStr,
            departureTime: returnDepartureTime,
            timeLabel: l10n.tripDetailsTime,
            originName:
                widget.destinationRouteStop?.stopName(locale) ??
                widget.trip.destinationName(locale),
            originLocality: widget.destinationRouteStop?.locality(locale),
            destinationName:
                widget.routeStop?.stopName(locale) ??
                widget.trip.originName(locale),
            destinationLocality: widget.routeStop?.locality(locale),
            seatNumber: returnSeatNumber,
            seatLabel: isAr ? 'مقعد العودة' : 'Return Seat',
            fareLabel:
                '${bundle.returnBaseFarePoints.toInt()} ${l10n.pointsUnit}',
            isAr: isAr,
          ),
        ],
      );
    } else {
      journeyCard = _SingleLegCard(
        isOutbound: isOutbound,
        titleLabel: isOutbound ? l10n.directionOutbound : l10n.directionReturn,
        dateStr: todayStr,
        departureTime: AppTimeFormatter.formatTripOption(
          widget.trip,
          isArabic: isAr,
        ),
        timeLabel: l10n.tripDetailsTime,
        originName:
            widget.routeStop?.stopName(locale) ??
            widget.trip.originName(locale),
        originLocality: widget.routeStop?.locality(locale),
        destinationName:
            widget.destinationRouteStop?.stopName(locale) ??
            widget.trip.destinationName(locale),
        destinationLocality: widget.destinationRouteStop?.locality(locale),
        seatNumber: widget.seat.seatNumber,
        seatLabel: l10n.tripDetailsSeat,
        fareLabel: '${totalFare.toInt()} ${l10n.pointsUnit}',
        isAr: isAr,
      );
    }

    // 2. HOLD COUNTDOWN CHIP
    Widget countdownWidget = const SizedBox.shrink();
    if (_secondsRemaining > 0 || _isExpired) {
      countdownWidget = _HoldCountdownChip(
        secondsRemaining: _secondsRemaining,
        isExpired: _isExpired,
        onChooseSeatAgain: widget.onChooseSeatAgain,
      );
    }

    // 3. SURFACE B: FARE & WALLET BALANCE PANEL
    Widget farePanel;
    if (isBundle) {
      final bundle = widget.bundleHold!;
      farePanel = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E9F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outbound Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'سعر الذهاب' : 'Outbound Price',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${bundle.outboundBaseFarePoints.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Return Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'سعر العودة' : 'Return Price',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${bundle.returnBaseFarePoints.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'الإجمالي' : 'Subtotal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475467),
                  ),
                ),
                Text(
                  '${bundle.subtotalPoints.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475467),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Discount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      isAr
                          ? 'خصم الذهاب والعودة 15%'
                          : 'Round Trip Discount 15%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${bundle.discountPoints.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),

            // Total after discount (Hero)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'الإجمالي بعد الخصم' : 'Total After Discount',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),
                Text(
                  '${bundle.totalPoints.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            if (widget.userAvailablePoints >= 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Available Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.availableBalanceLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${widget.userAvailablePoints.toInt()} ${l10n.pointsUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasEnoughPoints
                          ? const Color(0xFF101828)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Balance After Booking
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.afterBookingLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${balanceAfterBooking.toInt()} ${l10n.pointsUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: hasEnoughPoints
                          ? const Color(0xFF16A34A)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      farePanel = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E9F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero TOTAL Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalFare.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.bookingSummaryTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${totalFare.toInt()} ${l10n.pointsUnit}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            if (widget.userAvailablePoints >= 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Available Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.availableBalanceLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${widget.userAvailablePoints.toInt()} ${l10n.pointsUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasEnoughPoints
                          ? const Color(0xFF101828)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Balance After Booking
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.afterBookingLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${balanceAfterBooking.toInt()} ${l10n.pointsUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: hasEnoughPoints
                          ? const Color(0xFF16A34A)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // 4. INSUFFICIENT BALANCE SOFT ALERT
    Widget? deficitWidget;
    if (!hasEnoughPoints) {
      deficitWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.notEnoughPointsDeficit(deficitPoints),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 5. REASSURANCE NOTE
    Widget reassuranceWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.reviewTicketNotice,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    // 6. CONFIRM CTA
    Widget ctaButton = AppButton(
      label: l10n.confirmBooking,
      icon: AppIcons.check,
      height: 54,
      isLoading: widget.isConfirming,
      onPressed: isConfirmEnabled ? widget.onConfirm : null,
    );

    // Compose animated structure
    if (disableAnim) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          journeyCard,
          if (_secondsRemaining > 0 || _isExpired) ...[
            const SizedBox(height: 12),
            countdownWidget,
          ],
          const SizedBox(height: 12),
          farePanel,
          if (deficitWidget != null) ...[
            const SizedBox(height: 12),
            deficitWidget,
          ],
          const SizedBox(height: 16),
          reassuranceWidget,
          const SizedBox(height: 16),
          ctaButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _cardFadeAnim,
          child: SlideTransition(position: _cardSlideAnim, child: journeyCard),
        ),
        if (_secondsRemaining > 0 || _isExpired) ...[
          const SizedBox(height: 12),
          FadeTransition(opacity: _countdownFadeAnim, child: countdownWidget),
        ],
        const SizedBox(height: 12),
        FadeTransition(opacity: _fareFadeAnim, child: farePanel),
        if (deficitWidget != null) ...[
          const SizedBox(height: 12),
          deficitWidget,
        ],
        const SizedBox(height: 16),
        reassuranceWidget,
        const SizedBox(height: 16),
        FadeTransition(opacity: _ctaFadeAnim, child: ctaButton),
      ],
    );
  }
}

class _SingleLegCard extends StatelessWidget {
  final bool isOutbound;
  final String titleLabel;
  final String dateStr;
  final String departureTime;
  final String timeLabel;
  final String originName;
  final String? originLocality;
  final String destinationName;
  final String? destinationLocality;
  final String seatNumber;
  final String seatLabel;
  final String fareLabel;
  final bool isAr;

  const _SingleLegCard({
    required this.isOutbound,
    required this.titleLabel,
    required this.dateStr,
    required this.departureTime,
    required this.timeLabel,
    required this.originName,
    this.originLocality,
    required this.destinationName,
    this.destinationLocality,
    required this.seatNumber,
    required this.seatLabel,
    required this.fareLabel,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Direction + Time Hero Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direction Pill + Date underneath
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOutbound
                            ? const Color(0xFFE7F2FA)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOutbound
                              ? const Color(0xFFBAE6FD)
                              : const Color(0xFFFDE68A),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOutbound
                                ? (isAr
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded)
                                : (isAr
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_back_rounded),
                            size: 13,
                            color: isOutbound
                                ? AppColors.primary
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            titleLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOutbound
                                  ? AppColors.primary
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),

                // Departure Time Hero
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      departureTime,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Route: Compact Vertical Path
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _CompactRouteView(
              originName: originName,
              originLocality: originLocality,
              destinationName: destinationName,
              destinationLocality: destinationLocality,
              isAr: isAr,
            ),
          ),

          // Bottom Metadata Row: Authentic Coach Seat Badge + Fare Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coach Bus Seat Badge
                _CoachSeatBadge(seatNumber: seatNumber, label: seatLabel),

                // Fare Tag in bottom row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fareLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Elegant Vertical Route Journey Path matching My Trips card style.
class _CompactRouteView extends StatelessWidget {
  final String originName;
  final String? originLocality;
  final String destinationName;
  final String? destinationLocality;
  final bool isAr;

  const _CompactRouteView({
    required this.originName,
    this.originLocality,
    required this.destinationName,
    this.destinationLocality,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LEFT TRACK: Origin Icon -> Continuous Dashed Line -> Destination Icon
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Origin Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),

                // Dashed line bridging directly between Origin and Destination icons
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: CustomPaint(
                      painter: _VerticalDashedLinePainter(
                        color: AppColors.primary.withValues(alpha: 0.55),
                      ),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                ),

                // Destination Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD49B00).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD49B00).withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Color(0xFFD49B00),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 2. RIGHT TEXT COLUMN: Origin Text & Destination Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Stop (From)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isAr ? 'من: ' : 'From: ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475467),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              originName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF101828),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (originLocality != null &&
                                originLocality!.isNotEmpty &&
                                originLocality != originName)
                              Text(
                                originLocality!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF667085),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Stop (To)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isAr ? 'إلى: ' : 'To: ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475467),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              destinationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF101828),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (destinationLocality != null &&
                                destinationLocality!.isNotEmpty &&
                                destinationLocality != destinationName)
                              Text(
                                destinationLocality!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF667085),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  const _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.2;
    const dashSpace = 2.8;
    double startY = 0;

    final x = size.width / 2;
    while (startY < size.height) {
      final endY = (startY + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CoachSeatBadge extends StatelessWidget {
  final String seatNumber;
  final String label;

  const _CoachSeatBadge({required this.seatNumber, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trip SVG Icon from Bottom Nav Bar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: NavSvgIcon(
              type: NavSvgType.trip,
              color: Colors.white,
              size: 19.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              seatNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF101828),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact Hold Countdown Chip (soft pill strip, no heavy borders).
class _HoldCountdownChip extends StatelessWidget {
  final int secondsRemaining;
  final bool isExpired;
  final VoidCallback? onChooseSeatAgain;

  const _HoldCountdownChip({
    required this.secondsRemaining,
    required this.isExpired,
    this.onChooseSeatAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isExpired || secondsRemaining <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timer_off_outlined,
              size: 16,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.holdExpiredMessage,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
            if (onChooseSeatAgain != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onChooseSeatAgain,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFFDC2626),
                ),
                child: Text(
                  l10n.chooseSeatAgain,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";
    final isUrgent = secondsRemaining <= 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFDBA74) : const Color(0xFFFDE68A),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 15,
            color: isUrgent ? const Color(0xFFEA580C) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.seatHeldFor(timeStr),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUrgent
                    ? const Color(0xFFC2410C)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
