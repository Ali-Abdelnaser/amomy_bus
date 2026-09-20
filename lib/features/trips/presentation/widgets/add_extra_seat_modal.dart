import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/localization/status_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../../../../core/widgets/amomy_floating_alert.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/widgets/professional_bus_seat_map.dart';
import '../cubit/passenger_trips_cubit.dart';

/// Modal bottom sheet for booking an extra seat on the same bus trip.
///
/// Features:
/// - Reuses the canonical 28-seat physical bus map ([ProfessionalBusSeatMap]).
/// - Shows trip summary (departure time, route, fare per seat).
/// - Highlights current booked seat(s) as already reserved by the passenger.
/// - Allows passenger to select another available seat.
/// - Confirms atomic hold + booking deduction, updating the passenger's today card with both seats.
class AddExtraSeatModal extends StatefulWidget {
  final PassengerTodayTrip trip;
  final PassengerTripsCubit tripsCubit;

  const AddExtraSeatModal({
    super.key,
    required this.trip,
    required this.tripsCubit,
  });

  static Future<void> show(
    BuildContext context, {
    required PassengerTodayTrip trip,
    required PassengerTripsCubit tripsCubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => AddExtraSeatModal(trip: trip, tripsCubit: tripsCubit),
    );
  }

  @override
  State<AddExtraSeatModal> createState() => _AddExtraSeatModalState();
}

class _AddExtraSeatModalState extends State<AddExtraSeatModal> {
  bool _isLoading = true;
  String? _error;
  List<TripSeat> _seats = [];
  TripSeat? _selectedExtraSeat;
  bool _isSubmitting = false;
  bool _seatFetchInFlight = false;
  bool _seatFetchQueued = false;
  StreamSubscription<void>? _seatUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
    _startSeatUpdatesSubscription();
  }

  @override
  void dispose() {
    _seatUpdatesSubscription?.cancel();
    super.dispose();
  }

  void _startSeatUpdatesSubscription() {
    final repo = getIt.isRegistered<BookingRepository>()
        ? getIt<BookingRepository>()
        : null;
    if (repo == null) return;

    _seatUpdatesSubscription?.cancel();
    _seatUpdatesSubscription = repo
        .subscribeToTripSeatUpdates(widget.trip.tripId)
        .listen(
          (_) => _fetchSeats(silent: true),
          onError: (error, stackTrace) {},
          cancelOnError: false,
        );
  }

  Future<void> _fetchSeats({bool silent = false}) async {
    if (_seatFetchInFlight) {
      if (silent) _seatFetchQueued = true;
      return;
    }

    _seatFetchInFlight = true;
    var showLoading = !silent;
    final repo = getIt.isRegistered<BookingRepository>()
        ? getIt<BookingRepository>()
        : null;

    if (repo == null) {
      setState(() {
        if (!silent) _isLoading = false;
        _error = 'Repository not available';
      });
      _seatFetchInFlight = false;
      return;
    }

    try {
      do {
        _seatFetchQueued = false;
        if (showLoading && mounted) {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          showLoading = false;
        }

        final result = await repo.getTripSeatMap(tripId: widget.trip.tripId);
        if (!mounted) return;

        result.fold(
          onSuccess: (seats) {
            final selectedSeatStillAvailable =
                _selectedExtraSeat != null &&
                seats.any(
                  (seat) =>
                      seat.seatId == _selectedExtraSeat!.seatId &&
                      seat.isAvailable,
                );
            setState(() {
              _seats = seats;
              _isLoading = false;
              if (!selectedSeatStillAvailable) {
                _selectedExtraSeat = null;
              }
            });
          },
          onError: (failure) {
            if (silent) return;
            setState(() {
              _error = StatusLocalizer.localizeError(context, failure);
              _isLoading = false;
            });
          },
        );
      } while (_seatFetchQueued && mounted);
    } finally {
      _seatFetchInFlight = false;
    }
  }

  Future<void> _confirmBookingExtraSeat() async {
    if (_selectedExtraSeat == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final repo = getIt<BookingRepository>();

    // 1. Create booking hold
    final holdResult = await repo.createBookingHold(
      tripId: widget.trip.tripId,
      seatId: _selectedExtraSeat!.seatId,
    );

    if (!mounted) return;

    await holdResult.fold(
      onSuccess: (hold) async {
        // 2. Confirm booking
        final confirmResult = await repo.confirmBooking(holdId: hold.holdId);
        if (!mounted) return;

        confirmResult.fold(
          onSuccess: (booking) {
            Navigator.of(context).pop();
            widget.tripsCubit.loadTripsHub();
            AmomyFloatingAlert.show(
              context,
              title: isAr
                  ? 'تم حجز المقعد (${_selectedExtraSeat!.seatNumber}) بنجاح!'
                  : 'Seat (${_selectedExtraSeat!.seatNumber}) booked successfully!',
              message: isAr
                  ? 'تمت إضافة المقعد إلى حجزك الحالي على هذه الرحلة.'
                  : 'Extra seat added to your booking for this trip.',
              variant: AmomyAlertVariant.success,
            );
          },
          onError: (failure) {
            setState(() => _isSubmitting = false);
            AmomyFloatingAlert.show(
              context,
              title: isAr ? 'فشل تأكيد المقعد الإضافي' : 'Confirmation failed',
              message: StatusLocalizer.localizeError(context, failure),
              variant: AmomyAlertVariant.error,
            );
          },
        );
      },
      onError: (failure) {
        setState(() => _isSubmitting = false);
        AmomyFloatingAlert.show(
          context,
          title: isAr ? 'تعذر حجز المقعد الإضافي' : 'Hold failed',
          message: StatusLocalizer.localizeError(context, failure),
          variant: AmomyAlertVariant.error,
        );
      },
    );
  }

  Set<String> get _currentSeatNumbers {
    final raw = widget.trip.seatNumber ?? '';
    return raw
        .split(RegExp(r'[,،]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final screenHeight = MediaQuery.of(context).size.height;
    final currentSeats = _currentSeatNumbers;

    final availableSeats = _seats
        .where((s) => s.isAvailable && !currentSeats.contains(s.seatNumber))
        .toList();
    final hasAvailable = availableSeats.isNotEmpty;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.airline_seat_recline_extra_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'إضافة مقعد إضافي' : 'Add Extra Seat',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF101828),
                            fontSize: 16,
                          ),
                        ),
                        AppSpacing.gapH2,
                        Text(
                          isAr
                              ? 'رحلة ${AppTimeFormatter.formatPassengerTodayTrip(widget.trip, isArabic: true)} — ${widget.trip.originName(isAr ? "ar" : "en")} ← ${widget.trip.destinationName(isAr ? "ar" : "en")}'
                              : '${AppTimeFormatter.formatPassengerTodayTrip(widget.trip, isArabic: false)} Trip — ${widget.trip.originName("en")} ← ${widget.trip.destinationName("en")}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF667085)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Trip & Seat Info Badge Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Row(
                  children: [
                    // Current seat(s)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isAr
                                  ? 'مقعدك: (${widget.trip.seatNumber ?? "—"})'
                                  : 'Your Seat: (${widget.trip.seatNumber ?? "—"})',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF344054),
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFD0D5DD),
                    ),
                    const SizedBox(width: 10),
                    // Fare
                    Row(
                      children: [
                        const Icon(
                          Icons.toll_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr
                              ? '${widget.trip.farePoints.toInt()} نقطة للمقعد'
                              : '${widget.trip.farePoints.toInt()} pts / seat',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.gapH10,

            // Seat Map Content
            Expanded(
              child: _isLoading
                  ? const Center(child: AmomyBusLoading())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.gapH12,
                          ElevatedButton(
                            onPressed: _fetchSeats,
                            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                          ),
                        ],
                      ),
                    )
                  : !hasAvailable
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_seat_outlined,
                              size: 48,
                              color: Color(0xFF98A2B3),
                            ),
                            AppSpacing.gapH12,
                            Text(
                              isAr
                                  ? 'لا توجد مقاعد إضافية شاغرة'
                                  : 'No extra seats available',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              isAr
                                  ? 'الحافلة ممتلئة بالكامل حاليًا. مقعدك الحالي محمي وهو المقعد (${widget.trip.seatNumber ?? "—"}).'
                                  : 'The bus is fully booked. Your current seat (${widget.trip.seatNumber ?? "—"}) is protected.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF667085),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ProfessionalBusSeatMap(
                        seats: _seats,
                        selectedSeat: _selectedExtraSeat,
                        onSeatTap: (seat) {
                          if (currentSeats.contains(seat.seatNumber)) {
                            AmomyFloatingAlert.show(
                              context,
                              title: isAr
                                  ? 'هذا مقعدك الحالي بالفعل'
                                  : 'Already your seat',
                              message: isAr
                                  ? 'المقعد (${seat.seatNumber}) محجوز لك مسبقًا.'
                                  : 'Seat (${seat.seatNumber}) is already booked by you.',
                              variant: AmomyAlertVariant.info,
                            );
                            return;
                          }
                          if (!seat.isAvailable) {
                            AmomyFloatingAlert.show(
                              context,
                              title: isAr
                                  ? 'المقعد غير متاح'
                                  : 'Seat unavailable',
                              variant: AmomyAlertVariant.warning,
                            );
                            return;
                          }
                          setState(() => _selectedExtraSeat = seat);
                        },
                      ),
                    ),
            ),

            // Bottom Confirmation Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 0, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedExtraSeat != null
                              ? (isAr
                                    ? 'المقعد الإضافي: (${_selectedExtraSeat!.seatNumber})'
                                    : 'Extra Seat: (${_selectedExtraSeat!.seatNumber})')
                              : (isAr
                                    ? 'اختر مقعدًا من الخريطة'
                                    : 'Select a seat from map'),
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.gapH2,
                        Text(
                          _selectedExtraSeat != null
                              ? (isAr
                                    ? 'سيتم خصم ${widget.trip.farePoints.toInt()} نقطة من محفظتك'
                                    : '${widget.trip.farePoints.toInt()} pts will be deducted')
                              : (isAr
                                    ? '${widget.trip.availableSeats} مقاعد متاحة'
                                    : '${widget.trip.availableSeats} seats available'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (_selectedExtraSeat != null && !_isSubmitting)
                          ? _confirmBookingExtraSeat
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE4E7EC),
                        disabledForegroundColor: const Color(0xFF98A2B3),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isAr ? 'تأكيد الحجز' : 'Confirm',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
