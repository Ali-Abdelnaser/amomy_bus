import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';
import '../../../tracking/domain/models/live_tracking_status.dart';
import '../../../tracking/presentation/cubit/tracking_cubit.dart';
import '../../../tracking/presentation/cubit/tracking_state.dart';
import '../../domain/entities/home_summary.dart';

/// Semantic display state of the upcoming trip card.
enum TripTrackingDisplayState {
  upcoming,
  live,
  assignmentPending,
  stale,
  progressionUnavailable,
  outsideTrackingWindow,
  tripNotActive,
  completed,
}

/// Redesigned PRIMARY Home card displaying the authoritative upcoming trip.
///
/// Complies strictly with AMOMY Phase 9 specifications:
/// - Primary card on the Home screen
/// - Uses backend-selected [summary.upcomingTrip] without local trip-priority filtering
/// - Displays direction, date/Today, Cairo-localized 12-hour departure time, boarding stop,
///   destination stop, seat number, and state-aware tracking badge
/// - Never reveals internal bus ID, plate, driver, or device ID
/// - Provides state-aware actions (Live Map during tracking, View Trip/Change Seat/Cancel Booking before operation)
/// - Compact, polished empty state respecting server-authoritative booking availability
class HomeUpcomingTripCard extends StatelessWidget {
  final PassengerUpcomingTrip? upcomingTrip;
  final bool isBookingAvailable;
  final bool hasLoadedAvailability;
  final VoidCallback? onViewLiveMap;
  final VoidCallback? onViewTrip;
  final VoidCallback? onChangeSeat;
  final VoidCallback? onCancelBooking;

  const HomeUpcomingTripCard({
    super.key,
    this.upcomingTrip,
    this.isBookingAvailable = true,
    this.hasLoadedAvailability = false,
    this.onViewLiveMap,
    this.onViewTrip,
    this.onChangeSeat,
    this.onCancelBooking,
  });

  TripTrackingDisplayState _resolveDisplayState(
    PassengerUpcomingTrip trip,
    TrackingState? trackingState,
  ) {
    if (trip.bookingStatus == 'completed') {
      return TripTrackingDisplayState.completed;
    }
    if (trackingState != null &&
        (trackingState.summary?.activeTripId == trip.tripId ||
            trackingState.trackedTripId == trip.tripId)) {
      if (trackingState.isLive || trackingState.isOnline) {
        return TripTrackingDisplayState.live;
      }
      if (trackingState.isAssignmentPending) {
        return TripTrackingDisplayState.assignmentPending;
      }
      if (trackingState.isStale) {
        return TripTrackingDisplayState.stale;
      }
      if (trackingState.isProgressionUnavailable) {
        return TripTrackingDisplayState.progressionUnavailable;
      }
      if (trackingState.trackingStatus ==
          LiveTrackingStatus.outsideTrackingWindow) {
        return TripTrackingDisplayState.outsideTrackingWindow;
      }
      if (trackingState.trackingStatus == LiveTrackingStatus.tripNotActive) {
        return TripTrackingDisplayState.tripNotActive;
      }
    }
    return TripTrackingDisplayState.upcoming;
  }

  bool _isDateToday(DateTime date, {String? cairoDateStr}) {
    if (cairoDateStr != null && cairoDateStr.isNotEmpty) {
      final parts = cairoDateStr.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y == date.year && m == date.month && d == date.day) {
          return true;
        }
      }
    }
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showTicketModal(BuildContext context, PassengerUpcomingTrip trip) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (modalContext) {
        return AmomySheetContainer(
          hasBottomNav: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title & Subtitle
                Text(
                  l10n.qrTicketInstruction,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH4,
                Text(
                  '${trip.originName(locale)} → ${trip.destinationName(locale)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH16,

                // QR Code
                AppQrTicketWidget(data: trip.qrToken, size: 180),
                AppSpacing.gapH16,

                // Ticket meta row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetaCell(
                        icon: AppIcons.calendar,
                        label: l10n.tripDetailsDate,
                        value:
                            "${trip.serviceDate.year}-${trip.serviceDate.month.toString().padLeft(2, '0')}-${trip.serviceDate.day.toString().padLeft(2, '0')}",
                      ),
                      _MetaCell(
                        icon: AppIcons.clock,
                        label: l10n.tripDetailsTime,
                        value: AppTimeFormatter.formatUpcomingTrip(
                          trip,
                          isArabic: locale.startsWith('ar'),
                        ),
                      ),
                      _MetaCell(
                        icon: AppIcons.seat,
                        label: l10n.tripDetailsSeat,
                        value: trip.seatNumber,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: l10n.dismiss,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');
    final trip = upcomingTrip;

    // Safe retrieval of TrackingState without throwing if TrackingCubit is absent
    TrackingState? trackingState;
    try {
      trackingState = context.watch<TrackingCubit>().state;
    } catch (_) {
      trackingState = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header: Title + Link to My Trips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.upcomingTrip,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => context.go(RoutePaths.trips),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  l10n.navMyTrips,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,

        // Content: Digital Ticket Card or Ticket Stub Empty State
        if (trip != null) ...[
          _buildUpcomingTripCard(context, trip, trackingState, isAr, locale),
        ] else ...[
          _buildEmptyState(context, isAr),
        ],
      ],
    );
  }

  Widget _buildUpcomingTripCard(
    BuildContext context,
    PassengerUpcomingTrip trip,
    TrackingState? trackingState,
    bool isAr,
    String locale,
  ) {
    final l10n = context.l10n;
    final displayState = _resolveDisplayState(trip, trackingState);
    final isLive = displayState == TripTrackingDisplayState.live;
    final isToday = _isDateToday(
      trip.serviceDate,
      cairoDateStr: trackingState?.summary?.cairoDate,
    );
    final dateDisplay = isToday
        ? (isAr ? 'اليوم' : 'Today')
        : "${trip.serviceDate.year}-${trip.serviceDate.month.toString().padLeft(2, '0')}-${trip.serviceDate.day.toString().padLeft(2, '0')}";

    final boardingStopName =
        trip.stopNameAr != null && trip.stopNameAr!.isNotEmpty
        ? trip.stopNameAr!
        : trip.originName(locale);
    final destinationStopName = trip.destinationName(locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? const Color(0xFF10B981) : AppColors.border,
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : AppColors.primaryDarker.withValues(alpha: 0.06),
            blurRadius: isLive ? 22 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Ticket Header: Direction + State-aware Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLive ? const Color(0xFFF0FDF4) : AppColors.surfaceSoft,
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Direction Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AmomyBusIcon(size: 15, color: AppColors.primary),
                      AppSpacing.gapW6,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trip.direction == 'outbound'
                              ? l10n.directionOutbound
                              : l10n.directionReturn,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // State-aware Status Pill
                  _buildStatusPill(displayState, context),
                ],
              ),
            ),

            // 2. Ticket Body: Boarding Stop -> Destination + Cairo Departure Time
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Route Timeline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Origin / Boarding Stop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppSpacing.gapW8,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    boardingStopName,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (trip.stopNameAr != null &&
                                      trip.stopNameAr!.isNotEmpty &&
                                      trip.stopNameAr !=
                                          trip.originName(locale))
                                    Text(
                                      trip.originName(locale),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Connecting Timeline Line
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 3.5),
                          child: Container(
                            height: 16,
                            width: 1.5,
                            color: AppColors.border,
                          ),
                        ),

                        // Destination Stop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accentYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppSpacing.gapW8,
                            Expanded(
                              child: Text(
                                destinationStopName,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                  AppSpacing.gapW14,

                  // Hero Cairo Departure Time Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppTimeFormatter.formatUpcomingTrip(
                            trip,
                            isArabic: isAr,
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          l10n.tripDetailsTime,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Ticket Perforated Divider
            const _TicketPerforatedDivider(),

            // 4. Ticket Footer: Date/Today, Seat, Fare & State-aware Actions
            Container(
              color: AppColors.surfaceSoft,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Compact Meta Chips Row
                  Row(
                    children: [
                      Expanded(
                        child: _TicketMetaChip(
                          icon: AppIcons.calendar,
                          label: dateDisplay,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _TicketMetaChip(
                          icon: AppIcons.seat,
                          label: '${l10n.tripDetailsSeat} ${trip.seatNumber}',
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: _TicketMetaChip(
                          icon: AppIcons.ticket,
                          label: '${trip.farePoints} ${l10n.pointsUnit}',
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,

                  // State-aware Actions
                  if (isLive) ...[
                    // During Live Tracking: Primary "View Live Map" + Secondary "View Ticket"
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (onViewLiveMap != null) {
                                  onViewLiveMap!();
                                } else {
                                  context.push(
                                    RoutePaths.liveTracking.replaceFirst(
                                      ':tripId',
                                      trip.tripId,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.map_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                l10n.viewLiveMap,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: () => _showTicketModal(context, trip),
                              icon: const Icon(
                                AppIcons.qrCode,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                l10n.viewTicket,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Before Operation: Primary "View Ticket" (QR) + Secondary Action Links
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () => _showTicketModal(context, trip),
                        icon: const Icon(
                          AppIcons.qrCode,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          l10n.viewTicket,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapH8,

                    // Secondary Pre-Operation Actions: View Trip · Change Seat · Cancel Booking
                    Row(
                      children: [
                        Expanded(
                          child: _ActionChipButton(
                            icon: Icons.confirmation_number_outlined,
                            label: l10n.viewTrip,
                            onTap: () {
                              if (onViewTrip != null) {
                                onViewTrip!();
                              } else {
                                context.go(RoutePaths.trips);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionChipButton(
                            icon: Icons.event_seat_outlined,
                            label: l10n.changeSeat,
                            onTap: () {
                              if (onChangeSeat != null) {
                                onChangeSeat!();
                              } else {
                                context.go(RoutePaths.trips);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionChipButton(
                            icon: Icons.cancel_outlined,
                            label: l10n.cancelBooking,
                            isDestructive: true,
                            onTap: () {
                              if (onCancelBooking != null) {
                                onCancelBooking!();
                              } else {
                                context.go(RoutePaths.trips);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(
    TripTrackingDisplayState state,
    BuildContext context,
  ) {
    final l10n = context.l10n;
    final String label;
    final Color textColor;
    final Color bgColor;
    final Color borderColor;
    final IconData icon;

    switch (state) {
      case TripTrackingDisplayState.live:
        label = l10n.trackingLive;
        textColor = const Color(0xFF059669);
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        icon = Icons.radar_rounded;
      case TripTrackingDisplayState.assignmentPending:
        label = l10n.trackingAssignmentPending;
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.access_time_rounded;
      case TripTrackingDisplayState.stale:
        label = l10n.trackingLocationUnavailable;
        textColor = const Color(0xFFC2410C);
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFED7AA);
        icon = Icons.wifi_off_rounded;
      case TripTrackingDisplayState.progressionUnavailable:
        label = l10n.trackingProgressUnavailable;
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFCBD5E1);
        icon = Icons.alt_route_rounded;
      case TripTrackingDisplayState.outsideTrackingWindow:
        label = l10n.trackingUnavailable;
        textColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        icon = Icons.timer_off_rounded;
      case TripTrackingDisplayState.tripNotActive:
        label = l10n.trackingTripNotActive;
        textColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        icon = Icons.event_busy_rounded;
      case TripTrackingDisplayState.completed:
        label = l10n.tripStatusCompleted;
        textColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        icon = Icons.done_all_rounded;
      case TripTrackingDisplayState.upcoming:
        label = l10n.bookingStatusConfirmed;
        textColor = AppColors.primary;
        bgColor = AppColors.primaryLight;
        borderColor = AppColors.primary.withValues(alpha: 0.2);
        icon = Icons.confirmation_number_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    final l10n = context.l10n;
    final isCtaDisabled = hasLoadedAvailability && !isBookingAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: AmomyBusIcon(size: 20, color: AppColors.primary),
            ),
          ),
          AppSpacing.gapW14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.noUpcomingTrip,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isCtaDisabled
                      ? l10n.noMoreTripsAvailableToday
                      : l10n.bookRideSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isCtaDisabled
                        ? const Color(0xFFDC2626)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.gapW10,
          ElevatedButton(
            onPressed: isCtaDisabled
                ? null
                : () => context.push(RoutePaths.bookTrip),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCtaDisabled
                  ? const Color(0xFF94A3B8)
                  : AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.bookTripCta,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact secondary action chip for pre-operation actions
class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF334155);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle perforated divider with edge circular cut-out notches for ticket effect.
class _TicketPerforatedDivider extends StatelessWidget {
  const _TicketPerforatedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed perforation line
          Positioned(
            left: 14,
            right: 14,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dashWidth = 4.0;
                const dashSpace = 3.0;
                final count = (constraints.maxWidth / (dashWidth + dashSpace))
                    .floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(count, (_) {
                    return Container(
                      width: dashWidth,
                      height: 1.2,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(0.6),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Left circular notch cut-out
          Positioned(
            left: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
            ),
          ),

          // Right circular notch cut-out
          Positioned(
            right: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact digital ticket meta chip
class _TicketMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TicketMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          AppSpacing.gapW4,
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            AppSpacing.gapW4,
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        AppSpacing.gapH2,
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
