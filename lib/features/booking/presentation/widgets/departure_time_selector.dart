import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/services/passenger_booking_availability.dart';

/// Clean, vertical radio-list departure time selector for today's trips.
///
/// Features:
/// - Vertically stacked full-width rows (not horizontal chips).
/// - Radio-button indicator behavior (○ unselected, ● selected).
/// - AMOMY styling:
///   * Selected: Pale blue surface, primary blue border, bold time typography.
///   * Unselected: Crisp white card, subtle border, muted secondary text.
///   * Specific Trip entry (`isTripLocked: true`): Reuses the exact same premium
///     selected radio-row visual, non-interactive without fake change buttons.
/// - Subtle availability cues ("Available", "Few seats left") without
///   raw seat count noise.
/// - End-of-day empty state when no bookable trips remain.
class DepartureTimeSelector extends StatefulWidget {
  final List<TripOption> trips;
  final TripOption? selectedTrip;
  final BookingDirection direction;
  final bool isTripLocked;
  final bool isLoading;
  final ValueChanged<TripOption> onTripSelected;

  const DepartureTimeSelector({
    super.key,
    required this.trips,
    required this.selectedTrip,
    required this.direction,
    this.isTripLocked = false,
    this.isLoading = false,
    required this.onTripSelected,
  });

  @override
  State<DepartureTimeSelector> createState() => _DepartureTimeSelectorState();
}

class _DepartureTimeSelectorState extends State<DepartureTimeSelector>
    with WidgetsBindingObserver {
  Timer? _cutoffTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleCutoffTimer();
  }

  @override
  void didUpdateWidget(covariant DepartureTimeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trips != widget.trips ||
        oldWidget.selectedTrip != widget.selectedTrip) {
      _scheduleCutoffTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleCutoffTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cutoffTimer?.cancel();
    super.dispose();
  }

  void _scheduleCutoffTimer() {
    _cutoffTimer?.cancel();
    _cutoffTimer = null;

    final now = PassengerBookingAvailability.currentNow;
    DateTime? earliestCutoff;

    for (final trip in widget.trips) {
      final cutoff = trip.bookingCloseAt;
      if (cutoff != null && cutoff.isAfter(now)) {
        if (earliestCutoff == null || cutoff.isBefore(earliestCutoff)) {
          earliestCutoff = cutoff;
        }
      }
    }

    final selectedCutoff = widget.selectedTrip?.bookingCloseAt;
    if (selectedCutoff != null && selectedCutoff.isAfter(now)) {
      if (earliestCutoff == null || selectedCutoff.isBefore(earliestCutoff)) {
        earliestCutoff = selectedCutoff;
      }
    }

    if (earliestCutoff != null) {
      final duration =
          earliestCutoff.difference(now) + const Duration(milliseconds: 100);
      _cutoffTimer = Timer(duration, () {
        if (mounted) {
          setState(() {});
          _scheduleCutoffTimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          context.l10n.departureTimeTitle,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Loading State: Vertical Skeleton Placeholders
        if (widget.isLoading)
          Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 64,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        // 2. Specific Trip Entry: Locked single selected trip row
        else if (widget.isTripLocked && widget.selectedTrip != null)
          _DepartureTimeCard(
            trip: widget.selectedTrip!,
            direction: widget.direction,
            isSelected: true,
            isLocked: true,
            isAr: isAr,
            onTap: null,
          )
        // 3. No Available Trips Left
        else if (widget.trips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    AppIcons.clock,
                    size: 22,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.noTripsAvailableToday,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'تابع التطبيق غداً لمواعيد الرحلات الجديدة.'
                      : 'Check back tomorrow for the next trips.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        // 4. Vertical Radio List of Trips
        else
          Column(
            children: widget.trips.map((trip) {
              final isSelected = widget.selectedTrip?.tripId == trip.tripId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DepartureTimeCard(
                  trip: trip,
                  direction: widget.direction,
                  isSelected: isSelected,
                  isLocked: false,
                  isAr: isAr,
                  onTap: trip.canBook
                      ? () => widget.onTripSelected(trip)
                      : null,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DepartureTimeCard extends StatelessWidget {
  final TripOption trip;
  final BookingDirection direction;
  final bool isSelected;
  final bool isLocked;
  final bool isAr;
  final VoidCallback? onTap;

  const _DepartureTimeCard({
    required this.trip,
    required this.direction,
    required this.isSelected,
    required this.isLocked,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCutoff = trip.isBookingClosed();
    final isClosed = trip.isClosed || !trip.isBookable || isCutoff;
    final isFull = !isCutoff && !isClosed && trip.isFull;
    final isNotBookable = !trip.canBook;
    final isFewSeats = !isNotBookable && trip.availableSeatsCount <= 5;
    final isReturn =
        direction == BookingDirection.returnTrip ||
        trip.direction == BookingDirection.returnTrip;

    final l10n = context.l10n;

    // Status text determination
    String statusText;
    if (isCutoff) {
      statusText = isAr ? 'الحجز مغلق' : 'Booking closed';
    } else if (isClosed) {
      statusText = isAr ? 'الرحلة مغلقة' : 'Trip closed';
    } else if (isFull) {
      statusText = l10n.departureFullyBooked;
    } else if (isSelected) {
      statusText = isLocked
          ? l10n.departureSelectedTrip
          : l10n.departureSelected;
    } else {
      statusText = l10n.departureAvailable;
    }

    final cutoffInfo = (!isCutoff && trip.bookingCloseAt != null)
        ? ' · ${(isAr ? "الحجز حتى " : "Booking until ") + DateFormat("HH:mm").format(trip.bookingCloseAt!)}'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF0F9FF)
                : (isNotBookable ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isNotBookable
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFCBD5E1)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // 1. Radio Button Indicator
              _RadioIndicator(
                isSelected: isSelected,
                isFull: isFull || isNotBookable,
              ),

              const SizedBox(width: 14),

              // 2. Departure Time & Secondary Status
              Expanded(
                child: isReturn
                    ? Text(
                        AppTimeFormatter.formatTripOption(trip, isArabic: isAr),
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isSelected
                              ? AppColors.primaryDark
                              : (isFull || isNotBookable
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF101828)),
                          letterSpacing: -0.3,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppTimeFormatter.formatTripOption(
                              trip,
                              isArabic: isAr,
                            ),
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : (isFull || isNotBookable
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF101828)),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.departureBusAtFirstStop(
                              l10n.mitFadalaStopName,
                            ),
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : (isFull || isNotBookable
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                AppIcons.location,
                                size: 12,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${l10n.firstStopLabel} · $statusText$cutoffInfo',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF64748B),
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

              // 3. Subtle Non-Intrusive Metadata Badge
              if (isCutoff)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAr ? 'الحجز مغلق' : 'Booking closed',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              else if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAr ? 'مكتمل' : 'Full',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              else if (isFewSeats)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    isAr ? 'مقاعد محدودة' : 'Few seats left',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                )
              else if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  final bool isFull;

  const _RadioIndicator({required this.isSelected, required this.isFull});

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2.0),
          color: Colors.white,
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isFull ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        color: Colors.transparent,
      ),
    );
  }
}
