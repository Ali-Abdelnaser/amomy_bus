import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../../../../core/widgets/amomy_floating_alert.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/widgets/bus_seat_map_widget.dart';
import '../cubit/passenger_trips_cubit.dart';

/// Modal bottom sheet for changing a passenger's seat within the 30-minute cutoff window.
///
/// Adheres strictly to the product contract:
/// - Reuses the canonical 28-seat physical bus map ([ProfessionalBusSeatMap]).
/// - Current seat is clearly identified and protected.
/// - Only alternate available seats can be selected.
/// - If no other seats are available, shows prominent "No other seats available" message and preserves current seat.
/// - Changing seat is atomic: no fare change, no wallet debit/credit, server-validated.
class ChangeSeatModal extends StatefulWidget {
  final PassengerTodayTrip trip;
  final PassengerTripsCubit tripsCubit;

  const ChangeSeatModal({
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: false,
      builder: (_) => ChangeSeatModal(trip: trip, tripsCubit: tripsCubit),
    );
  }

  @override
  State<ChangeSeatModal> createState() => _ChangeSeatModalState();
}

class _ChangeSeatModalState extends State<ChangeSeatModal> {
  bool _isLoading = true;
  String? _error;
  List<TripSeat> _seats = [];
  TripSeat? _selectedNewSeat;
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
                _selectedNewSeat != null &&
                seats.any(
                  (seat) =>
                      seat.seatId == _selectedNewSeat!.seatId &&
                      seat.isAvailable,
                );
            setState(() {
              _seats = seats;
              _isLoading = false;
              if (!selectedSeatStillAvailable) {
                _selectedNewSeat = null;
              }
            });
          },
          onError: (failure) {
            if (silent) return;
            setState(() {
              _error = failure.message;
              _isLoading = false;
            });
          },
        );
      } while (_seatFetchQueued && mounted);
    } finally {
      _seatFetchInFlight = false;
    }
  }

  Future<void> _onConfirmChange() async {
    if (_selectedNewSeat == null || widget.trip.bookingId == null) return;

    setState(() => _isSubmitting = true);

    final success = await widget.tripsCubit.changeBookingSeat(
      bookingId: widget.trip.bookingId!,
      newSeatId: _selectedNewSeat!.seatId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      final isAr = Localizations.localeOf(
        context,
      ).languageCode.startsWith('ar');
      AmomyFloatingAlert.show(
        context,
        title: isAr
            ? 'تم تغيير المقعد بنجاح إلى مقعد ${_selectedNewSeat!.seatNumber}'
            : 'Seat successfully changed to Seat ${_selectedNewSeat!.seatNumber}',
        variant: AmomyAlertVariant.success,
      );
    } else {
      final isAr = Localizations.localeOf(
        context,
      ).languageCode.startsWith('ar');
      AmomyFloatingAlert.show(
        context,
        title:
            widget.tripsCubit.state.errorMessage ??
            (isAr ? 'فشل تغيير المقعد' : 'Failed to change seat'),
        variant: AmomyAlertVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final currentSeatNumber = widget.trip.seatNumber ?? '—';

    // Find other available seats
    final otherAvailableSeats = _seats
        .where((s) => s.isAvailable && s.seatNumber != currentSeatNumber)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Top Title Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'تغيير المقعد' : 'Change Seat',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF101828),
                          ),
                        ),
                        AppSpacing.gapH2,
                        Text(
                          isAr
                              ? 'رحلة ${widget.trip.departureTime} — مقعدك الحالي: $currentSeatNumber'
                              : '${widget.trip.departureTime} Trip — Current seat: $currentSeatNumber',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: const Color(0xFF667085),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE4E7EC)),

            // Body Area
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(child: AmomyBusLoading.medium());
                  }

                  if (_error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: AppColors.error,
                            ),
                            AppSpacing.gapH12,
                            Text(
                              _error!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            AppSpacing.gapH16,
                            OutlinedButton(
                              onPressed: _fetchSeats,
                              child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // FULL BUS / NO OTHER SEATS AVAILABLE CASE
                  if (otherAvailableSeats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF6E7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF79009),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.airline_seat_recline_normal_rounded,
                                color: Color(0xFFB54708),
                                size: 30,
                              ),
                            ),
                            AppSpacing.gapH16,
                            Text(
                              isAr
                                  ? 'لا توجد مقاعد أخرى متاحة'
                                  : 'No other seats available',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF101828),
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            AppSpacing.gapH8,
                            Text(
                              isAr
                                  ? 'الحافلة ممتلئة بالكامل حاليًا. مقعدك الحالي محمي وهو المقعد ($currentSeatNumber).'
                                  : 'The bus is currently fully booked. Your current seat is protected as Seat $currentSeatNumber.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF475467),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            AppSpacing.gapH24,
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isAr ? 'إغلاق' : 'Close',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // INTERACTIVE SEAT MAP
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      children: [
                        // Informative Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FDF7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'مقعدك الحالي ($currentSeatNumber) يظل محميًا حتى يتم تأكيد المقعد الجديد.'
                                      : 'Your current seat ($currentSeatNumber) remains protected until a new seat is confirmed.',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF027A48),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        AppSpacing.gapH12,

                        // Physical 28-Seat Bus Map
                        BusSeatMapWidget(
                          seats: _seats,
                          selectedSeat: _selectedNewSeat,
                          onSeatTap: (seat) {
                            if (seat.seatNumber == currentSeatNumber) {
                              AmomyFloatingAlert.show(
                                context,
                                title: isAr
                                    ? 'هذا هو مقعدك الحالي المحجوز'
                                    : 'This is your current booked seat',
                                variant: AmomyAlertVariant.info,
                              );
                              return;
                            }

                            if (!seat.isAvailable) {
                              AmomyFloatingAlert.show(
                                context,
                                title: isAr
                                    ? 'هذا المقعد غير متاح للاختيار'
                                    : 'This seat is unavailable',
                                variant: AmomyAlertVariant.warning,
                              );
                              return;
                            }

                            setState(() {
                              _selectedNewSeat = seat;
                            });
                          },
                        ),

                        AppSpacing.gapH12,

                        // Interactive Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendItem(
                              color: AppColors.success,
                              label: isAr ? 'مقعدك الحالي' : 'Current Seat',
                            ),
                            const SizedBox(width: 16),
                            _LegendItem(
                              color: AppColors.primary,
                              label: isAr ? 'مختار' : 'Selected',
                            ),
                            const SizedBox(width: 16),
                            const _LegendItem(
                              color: Color(0xFFE2E8F0),
                              labelBorder: Color(0xFF94A3B8),
                              label: 'متاح',
                            ),
                            const SizedBox(width: 16),
                            const _LegendItem(
                              color: Color(0xFF334155),
                              label: 'محجوز',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Confirm Button
            if (!_isLoading && _error == null && otherAvailableSeats.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_selectedNewSeat != null && !_isSubmitting)
                        ? _onConfirmChange
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.35,
                      ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _selectedNewSeat == null
                                ? (isAr
                                      ? 'اختر مقعدًا جديدًا'
                                      : 'Select a new seat')
                                : (isAr
                                      ? 'تأكيد الانتقال إلى مقعد (${_selectedNewSeat!.seatNumber})'
                                      : 'Confirm Change to Seat (${_selectedNewSeat!.seatNumber})'),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? labelBorder;
  final String label;

  const _LegendItem({
    required this.color,
    this.labelBorder,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: labelBorder != null
                ? Border.all(color: labelBorder!, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 11,
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
