import 'package:amomy_bus/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../shell/presentation/widgets/nav_svg_icon.dart';
import '../cubit/passenger_trips_cubit.dart';
import 'add_extra_seat_modal.dart';
import 'qr_ticket_modal.dart';
import 'trip_ticket_svg_background.dart';
import 'booked_trip_overflow_menu.dart';

/// Premium, ticket-shaped daily trip card for AMOMY My Trips Hub.
///
/// Layout Architecture:
/// - Base: Authentic SVG Ticket Geometry ([TripTicketSvgBackground] replicating assets/trip_ticket.svg).
/// - Divider Ratio: Exact 235.9 / 939.0 (≈ 25.12%) from SVG source of truth.
/// - Small Zone (~25.12%): Compact metadata stack (Status, Time with pulsing dot, Seat with Nav Trips SVG, Fare with Nav Wallet SVG). All text is strong dark.
/// - Large Zone (~74.88%): Vertical From/To route with pins, labels, vertical dashed connector, and Action buttons.
/// - Neither zone ever crosses into the other across the vertical perforation line.
class TodayTripCard extends StatelessWidget {
  final PassengerTodayTrip trip;
  final PassengerTripPreference? preference;
  final int animationIndex;

  const TodayTripCard({
    super.key,
    required this.trip,
    this.preference,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');
    final isCheckedIn = trip.isCheckedIn;
    final isCompleted = trip.status == 'completed';
    final isDeparted = isCompleted ||
        trip.availabilityStatus == TodayTripAvailabilityStatus.departed;
    final isBooked =
        trip.alreadyBooked && !isCheckedIn && !isCompleted && !isDeparted;
    final isAvailable =
        trip.isBookable && !isCheckedIn && !isCompleted && !isDeparted;
    final isFull =
        trip.availabilityStatus == TodayTripAvailabilityStatus.full ||
        (!isBooked &&
            !isCheckedIn &&
            !isCompleted &&
            !isDeparted &&
            trip.availableSeats <= 0);
    final isReturn = trip.direction == BookingDirection.returnTrip;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // 1. Resolve stop names:
    // - Booked/Checked-in trip: use passenger's actual booked boarding & destination stops
    // - Available trip: use preferred journey if set and non-empty, otherwise route endpoints
    String displayOrigin;
    String displayDest;

    if (isBooked || isCheckedIn) {
      displayOrigin = trip.originName(locale);
      displayDest = trip.destinationName(locale);
    } else if (preference != null &&
        preference!.originName(locale).trim().isNotEmpty &&
        preference!.destinationName(locale).trim().isNotEmpty) {
      if (trip.direction == BookingDirection.outbound) {
        displayOrigin = preference!.originName(locale);
        displayDest = preference!.destinationName(locale);
      } else {
        // Return journey: Origin is passenger's destination (university) and Dest is boarding stop (home)
        displayOrigin = preference!.destinationName(locale);
        displayDest = preference!.originName(locale);
      }
    } else {
      displayOrigin = trip.originName(locale);
      displayDest = trip.destinationName(locale);
    }

    // Bulletproof non-empty fallback
    if (displayOrigin.trim().isEmpty) {
      displayOrigin = isAr ? trip.originNameAr : trip.originNameEn;
      if (displayOrigin.trim().isEmpty) {
        displayOrigin = trip.originNameAr.isNotEmpty
            ? trip.originNameAr
            : trip.originNameEn;
      }
    }
    if (displayDest.trim().isEmpty) {
      displayDest = isAr ? trip.destinationNameAr : trip.destinationNameEn;
      if (displayDest.trim().isEmpty) {
        displayDest = trip.destinationNameAr.isNotEmpty
            ? trip.destinationNameAr
            : trip.destinationNameEn;
      }
    }

    // Colors according to visual language rules:
    final Color cardBackground;
    final Color cardBorder;
    final Color accentColor;
    final Color shadowColor;
    final Color timeDotColor;

    if (isCheckedIn || isCompleted) {
      cardBackground = const Color(0xFFF8F9FA);
      cardBorder = const Color(0xFFE2E8F0);
      accentColor = AppColors.textTertiary;
      shadowColor = Colors.black.withValues(alpha: 0.02);
      timeDotColor = const Color(0xFF94A3B8);
    } else if (isBooked) {
      cardBackground = const Color(0xFFF4FDF7);
      cardBorder = AppColors.success.withValues(alpha: 0.40);
      accentColor = AppColors.success;
      shadowColor = AppColors.success.withValues(alpha: 0.08);
      timeDotColor = AppColors.success;
    } else if (isDeparted) {
      cardBackground = const Color(0xFFF8F9FA);
      cardBorder = const Color(0xFFE2E8F0);
      accentColor = AppColors.textTertiary;
      shadowColor = Colors.black.withValues(alpha: 0.02);
      timeDotColor = const Color(0xFF94A3B8);
    } else if (isReturn) {
      cardBackground = const Color(0xFFFFFEFA);
      cardBorder = const Color(0xFFFFC928).withValues(alpha: 0.45);
      accentColor = const Color(0xFFD49B00);
      shadowColor = const Color(0xFFFFC928).withValues(alpha: 0.08);
      timeDotColor = const Color(0xFFD49B00);
    } else {
      // Outbound available
      cardBackground = Colors.white;
      cardBorder = AppColors.primary.withValues(alpha: 0.22);
      accentColor = AppColors.primary;
      shadowColor = AppColors.primary.withValues(alpha: 0.07);
      timeDotColor = AppColors.primary;
    }

    final cardHeight =
        (isDeparted || isCheckedIn || isCompleted) ? 102.0 : 144.0;

    Widget cardContent = SizedBox(
      height: cardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // Divider ratio calculated from assets/trip_ticket.svg (235.9 / 939.0 ≈ 0.2512247)
          final smallZoneWidth =
              totalWidth * TripTicketSvgBackground.dividerRatio;
          final largeZoneWidth = totalWidth - smallZoneWidth;

          return Stack(
            children: [
              // 1. Real Ticket SVG Background Base
              Positioned.fill(
                child: TripTicketSvgBackground(
                  fillColor: cardBackground,
                  borderColor: cardBorder,
                  borderWidth: 1.0,
                  shadowColor: shadowColor,
                  elevation: isDeparted ? 1.0 : 3.5,
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
                  // 2. Time (with pulsing dot & dark text)
                  // 3. Seat (with Nav Trips SVG & dark text)
                  // 4. Price (with Nav Wallet SVG & dark text)
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
                          // 1. STATUS BADGE (Top of small stub)
                          _buildCompactStatusBadge(
                            isAr: isAr,
                            isBooked: isBooked,
                            isCheckedIn: isCheckedIn,
                            isCompleted: isCompleted,
                            isFull: isFull,
                            isDeparted: isDeparted,
                            isReturn: isReturn,
                          ),

                          // 2. TIME ROW WITH ANIMATED/PULSING DOT + DARK TIME TEXT
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PulsingTimeDot(
                                color: timeDotColor,
                                isLive: !isDeparted && !isCheckedIn,
                                disableAnimations: disableAnimations,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppTimeFormatter.formatPassengerTodayTrip(
                                    trip,
                                    locale: locale,
                                  ),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isDeparted
                                        ? AppColors.textTertiary
                                        : const Color(0xFF101828),
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // 3. SEAT ROW (Green/State Nav Trips SVG + Dark Text)
                          if (isBooked)
                            Builder(
                              builder: (context) {
                                final seatStr = trip.seatNumber ?? '—';
                                final seatsList = seatStr
                                    .split(RegExp(r'[,،]'))
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                                final isMulti = seatsList.length > 1;
                                final isOverflow = seatsList.length > 2;

                                void showSeatsDialog() {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AppDialog(
                                      title: isAr
                                          ? 'المقاعد المحجوزة'
                                          : 'Booked Seats',
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isAr
                                                ? 'تم حجز ${seatsList.length} مقاعد لهذه الرحلة'
                                                : '${seatsList.length} seats booked for this trip',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            alignment: WrapAlignment.center,
                                            children: seatsList.map((seat) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEFF6FC,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const NavSvgIcon(
                                                      type: NavSvgType.trip,
                                                      color: AppColors.primary,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      isAr
                                                          ? 'مقعد $seat'
                                                          : 'Seat $seat',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .primaryDarker,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: Text(
                                            isAr ? 'إغلاق' : 'Close',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (isOverflow) {
                                  return InkWell(
                                    onTap: showSeatsDialog,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 1,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const NavSvgIcon(
                                            type: NavSvgType.trip,
                                            color: AppColors.success,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              isAr
                                                  ? '${seatsList.length} مقاعد'
                                                  : '${seatsList.length} Seats',
                                              style: AppTextStyles.titleSmall
                                                  .copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(
                                                      0xFF101828,
                                                    ),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.info_outline_rounded,
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const NavSvgIcon(
                                      type: NavSvgType.trip,
                                      color: AppColors.success,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr
                                                ? (isMulti
                                                      ? 'المقاعد'
                                                      : 'المقعد')
                                                : (isMulti ? 'Seats' : 'Seat'),
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  fontSize: 9.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF475467,
                                                  ),
                                                  height: 1.0,
                                                ),
                                          ),
                                          Text(
                                            seatStr,
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                                  fontSize: isMulti
                                                      ? 11.0
                                                      : 13.0,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(
                                                    0xFF101828,
                                                  ),
                                                  height: 1.1,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          else if (isDeparted)
                            const SizedBox.shrink()
                          else if (isFull)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const NavSvgIcon(
                                  type: NavSvgType.trip,
                                  color: AppColors.error,
                                  size: 13,
                                ),
                                const SizedBox(width: 3.5),
                                Flexible(
                                  child: Text(
                                    isAr ? '0 مقاعد' : '0 seats',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.error,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NavSvgIcon(
                                  type: NavSvgType.trip,
                                  color: isReturn
                                      ? const Color(0xFFD49B00)
                                      : AppColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 3.5),
                                Flexible(
                                  child: Text(
                                    isAr
                                        ? '${trip.availableSeats} مقاعد'
                                        : '${trip.availableSeats} seats',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: trip.isUrgentSeats
                                          ? const Color(0xFFB54708)
                                          : const Color(0xFF101828),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                          // 4. PRICE ROW (Green/State Nav Wallet SVG + Dark Text)
                          if (!isDeparted)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NavSvgIcon(
                                  type: NavSvgType.wallet,
                                  color: isBooked
                                      ? AppColors.success
                                      : (isReturn
                                            ? const Color(0xFFD49B00)
                                            : AppColors.primary),
                                  size: 13,
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  '${trip.farePoints.toInt()}',
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
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),

                  // ==========================================
                  // LARGE MAIN ZONE (74.88%):
                  // 1. From → To Route Visual (Upper ~55-60%)
                  // 2. Actions (Ticket & Companion / Book Now) (Lower zone)
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
                          // 1. FROM / TO VERTICAL ROUTE COMPOSITION (Redesigned with distinct badges & balanced position)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ROW 1: ORIGIN / BOARDING STOP (Matching Book Trip "From" identity)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDeparted
                                            ? const Color(0xFFF1F5F9)
                                            : AppColors.primary.withValues(
                                                alpha: 0.10,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDeparted
                                              ? const Color(0xFFE2E8F0)
                                              : AppColors.primary.withValues(
                                                  alpha: 0.22,
                                                ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.my_location_rounded,
                                        size: 13,
                                        color: isDeparted
                                            ? AppColors.textTertiary
                                            : AppColors.primary,
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
                                              color: isDeparted
                                                  ? AppColors.textTertiary
                                                  : const Color(0xFF101828),
                                              letterSpacing: -0.2,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // VERTICAL ROUTE CONNECTOR (Centered under the 24px origin badge)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 11.0,
                                  ),
                                  child: _VerticalRouteConnector(
                                    height: 7,
                                    color: accentColor,
                                    isDeparted: isDeparted,
                                  ),
                                ),
                                AppSpacing.gapH8,
                                // ROW 2: DESTINATION / DROP-OFF STOP (Matching Book Trip "To" identity)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDeparted
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(
                                                0xFFD49B00,
                                              ).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDeparted
                                              ? const Color(0xFFE2E8F0)
                                              : const Color(
                                                  0xFFD49B00,
                                                ).withValues(alpha: 0.25),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: isDeparted
                                            ? AppColors.textTertiary
                                            : const Color(0xFFD49B00),
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
                                              color: isDeparted
                                                  ? AppColors.textTertiary
                                                  : const Color(0xFF101828),
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

                          // 2. ACTION BUTTONS AREA (Lower zone)
                          if (isBooked)
                            Row(
                              children: [
                                // Ticket Button (~46% width)
                                Expanded(
                                  flex: 46,
                                  child: SizedBox(
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openQrModal(context),
                                      icon: const Icon(
                                        AppIcons.qrCode,
                                        size: 14,
                                      ),
                                      label: Text(
                                        isAr ? 'التذكرة' : 'Ticket',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Add Extra Seat Button (~54% width)
                                Expanded(
                                  flex: 54,
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        AddExtraSeatModal.show(
                                          context,
                                          trip: trip,
                                          tripsCubit: context
                                              .read<PassengerTripsCubit>(),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons
                                            .airline_seat_recline_extra_rounded,
                                        size: 15,
                                      ),
                                      label: Text(
                                        isAr ? 'إضافة مقعد' : 'Extra Seat',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.success,
                                        side: BorderSide(
                                          color: AppColors.success.withValues(
                                            alpha: 0.45,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Overflow Menu Action (⋮) for Change Seat & Cancel
                                BookedTripOverflowMenu(trip: trip),
                              ],
                            )
                          else if (isAvailable)
                            _BookNowButton(
                              isAr: isAr,
                              isReturn: isReturn,
                              onTap: () {
                                context.push(
                                  RoutePaths.bookTrip,
                                  extra: {
                                    'trip_id': trip.tripId,
                                    'direction': trip.direction,
                                    'origin_stop_id': preference?.originStopId,
                                    'destination_stop_id':
                                        preference?.destinationStopId,
                                  },
                                );
                              },
                            )
                          else
                            const SizedBox.shrink(),
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

    // Apply Departed soft opacity (0.78 readable)
    if (isDeparted) {
      cardContent = Opacity(opacity: 0.78, child: cardContent);
    }

    // Staggered entrance animation
    if (!disableAnimations) {
      final staggerDelay = (animationIndex * 50).clamp(0, 160);
      cardContent = cardContent
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

    return cardContent;
  }

  Widget _buildCompactStatusBadge({
    required bool isAr,
    required bool isBooked,
    bool isCheckedIn = false,
    bool isCompleted = false,
    required bool isFull,
    required bool isDeparted,
    required bool isReturn,
  }) {
    final String statusKey;
    final Widget badge;

    if (isCheckedIn || isCompleted) {
      statusKey = 'checked_in';
      badge = Container(
        key: const ValueKey('badge_checked_in'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          isAr ? 'منتهية' : 'Finished',
          style: AppTextStyles.labelSmall.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    } else if (isBooked) {
      statusKey = 'booked';
      badge = Container(
        key: const ValueKey('badge_booked'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Text(
          isAr ? 'محجوزة' : 'Booked',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    } else if (isDeparted) {
      statusKey = 'departed';
      badge = Container(
        key: const ValueKey('badge_departed'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          isAr ? 'انطلقت' : 'Departed',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    } else if (isFull) {
      statusKey = 'full';
      badge = Container(
        key: const ValueKey('badge_full'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
        ),
        child: Text(
          isAr ? 'اكتملت' : 'Full',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    } else if (isReturn) {
      statusKey = 'available_return';
      badge = Container(
        key: const ValueKey('badge_available_return'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF6E7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFD49B00).withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          isAr ? 'متاحة' : 'Available',
          style: AppTextStyles.labelSmall.copyWith(
            color: const Color(0xFFD49B00),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    } else {
      statusKey = 'available_outbound';
      badge = Container(
        key: const ValueKey('badge_available_outbound'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Text(
          isAr ? 'متاحة' : 'Available',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(statusKey), child: badge),
    );
  }

  void _openQrModal(BuildContext context) {
    if (trip.qrToken == null) return;
    final locale = Localizations.localeOf(context).languageCode;
    QrTicketModal.show(
      context,
      bookingId: trip.bookingId,
      departureTime: AppTimeFormatter.formatPassengerTodayTrip(
        trip,
        locale: locale,
      ),
      originName: trip.originName(locale),
      destinationName: trip.destinationName(locale),
      seatNumber: trip.seatNumber ?? '—',
      farePoints: trip.farePoints,
      qrToken: trip.qrToken!,
    );
  }
}

/// Subtle pulsing dot for live/active scheduled trips.
class _PulsingTimeDot extends StatefulWidget {
  final Color color;
  final bool isLive;
  final bool disableAnimations;

  const _PulsingTimeDot({
    required this.color,
    required this.isLive,
    required this.disableAnimations,
  });

  @override
  State<_PulsingTimeDot> createState() => _PulsingTimeDotState();
}

class _PulsingTimeDotState extends State<_PulsingTimeDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.90,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 0.90,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.55,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.55,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.isLive && !widget.disableAnimations) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingTimeDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !widget.disableAnimations) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive || widget.disableAnimations) {
      return Container(
        width: 5.5,
        height: 5.5,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.40),
                    blurRadius: 3.5,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Vertical dashed transit route connector connecting the From pin to the To pin.
class _VerticalRouteConnector extends StatelessWidget {
  final double height;
  final Color color;
  final bool isDeparted;

  const _VerticalRouteConnector({
    required this.height,
    required this.color,
    required this.isDeparted,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = isDeparted
        ? const Color(0xFFCBD5E1)
        : color.withValues(alpha: 0.55);

    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(
        size: Size(2, height),
        painter: _VerticalDashedLinePainter(color: lineColor),
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
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Responsive Book Now action button with interactive press scale.
class _BookNowButton extends StatefulWidget {
  final bool isAr;
  final bool isReturn;
  final VoidCallback onTap;

  const _BookNowButton({
    required this.isAr,
    required this.isReturn,
    required this.onTap,
  });

  @override
  State<_BookNowButton> createState() => _BookNowButtonState();
}

class _BookNowButtonState extends State<_BookNowButton> {
  bool _isButtonDown = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isReturn
        ? AppColors.accentYellow
        : AppColors.primary;
    final fgColor = widget.isReturn ? const Color(0xFF101828) : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonDown = true),
      onTapUp: (_) {
        setState(() => _isButtonDown = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isButtonDown = false),
      child: AnimatedScale(
        scale: _isButtonDown ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              if (!widget.isReturn)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.ticket, size: 14, color: fgColor),
              const SizedBox(width: 5),
              Text(
                widget.isAr ? 'احجز الآن' : 'Book Now',
                style: AppTextStyles.labelMedium.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
