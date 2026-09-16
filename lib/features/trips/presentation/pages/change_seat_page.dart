import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../../../../core/widgets/amomy_floating_alert.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/widgets/bus_seat_map_widget.dart';
import '../cubit/passenger_trips_cubit.dart';

/// Full-page interactive seat selection screen for changing a passenger's seat.
///
/// Shows the full 28-seat interior bus map with real-time seat availability,
/// gender status separation (male/female/available/occupied), protected current seat,
/// and instant confirmation.
class ChangeSeatPage extends StatefulWidget {
  final PassengerTodayTrip trip;
  final PassengerTripsCubit tripsCubit;

  const ChangeSeatPage({
    super.key,
    required this.trip,
    required this.tripsCubit,
  });

  @override
  State<ChangeSeatPage> createState() => _ChangeSeatPageState();
}

class _ChangeSeatPageState extends State<ChangeSeatPage> {
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

    // Find other available seats excluding the passenger's current seat
    final otherAvailableSeats = _seats
        .where((s) => s.isAvailable && s.seatNumber != currentSeatNumber)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleWidget: Text(
          isAr ? 'تغيير المقعد' : 'Change Seat',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF101828),
            letterSpacing: -0.4,
          ),
        ),
        showBackButton: true,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Center(
            child: Material(
              color: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-header Trip Summary Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
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
                          isAr
                              ? 'رحلة الساعة ${widget.trip.departureTime}'
                              : '${widget.trip.departureTime} Departure',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF101828),
                            fontSize: 15,
                          ),
                        ),
                        AppSpacing.gapH2,
                        Text(
                          isAr
                              ? 'مقعدك الحالي: مقعد ($currentSeatNumber)'
                              : 'Current Seat: Seat ($currentSeatNumber)',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area (Seat Map / Loading / Empty)
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
                              size: 44,
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

                  // Bus fully booked
                  if (otherAvailableSeats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
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
                                size: 32,
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
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isAr ? 'رجوع' : 'Go Back',
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

                  // 28-Seat Bus Map Layout
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      children: [
                        // Hint banner
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
                                      ? 'مقعدك الحالي ($currentSeatNumber) يظل محميًا حتى تأكيد المقعد الجديد.'
                                      : 'Your current seat ($currentSeatNumber) remains protected until new seat is confirmed.',
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

                        AppSpacing.gapH16,

                        // Comprehensive Interactive Bus Legend
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _LegendItem(
                              color: AppColors.success,
                              label: isAr ? 'مقعدك الحالي' : 'Current Seat',
                            ),
                            _LegendItem(
                              color: AppColors.primary,
                              label: isAr ? 'مختار' : 'Selected',
                            ),
                            const _LegendItem(
                              color: Color(0xFFE2E8F0),
                              labelBorder: Color(0xFF94A3B8),
                              label: 'متاح',
                            ),
                            _LegendItem(
                              color: const Color(0xFF0F172A),
                              label: isAr ? 'محجوز (رجال)' : 'Booked (M)',
                            ),
                            _LegendItem(
                              color: const Color(0xFFE11D48),
                              label: isAr ? 'محجوز (نساء)' : 'Booked (F)',
                            ),
                          ],
                        ),

                        AppSpacing.gapH16,

                        // Physical 28-Seat Bus Interior Map
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
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
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
                                      ? 'اختر مقعدًا جديدًا من المخطط'
                                      : 'Select a new seat from map')
                                : (isAr
                                      ? 'تأكيد الانتقال إلى مقعد (${_selectedNewSeat!.seatNumber})'
                                      : 'Confirm Change to Seat (${_selectedNewSeat!.seatNumber})'),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
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
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.5),
            border: labelBorder != null
                ? Border.all(color: labelBorder!, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 11.5,
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
