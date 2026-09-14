import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/direction_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/route_stop_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../../../../core/widgets/amomy_floating_alert.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/booking_entities.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_review_card.dart';
import '../widgets/booking_success_view.dart';
import '../widgets/bus_seat_map_widget.dart';

class BookTripPage extends StatelessWidget {
  final BookingCubit? bookingCubit;
  final String? initialTripId;
  final BookingDirection? initialDirection;
  final String? initialOriginStopId;
  final String? initialDestinationStopId;

  const BookTripPage({
    super.key,
    this.bookingCubit,
    this.initialTripId,
    this.initialDirection,
    this.initialOriginStopId,
    this.initialDestinationStopId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        if (!user.isProfileComplete) {
          return AppScaffold(
            appBar: AppAppBar(
              title: context.l10n.bookRideTitle,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: AppSpacing.edgeInsetsA24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.user,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      AppSpacing.gapH24,
                      Text(
                        context.l10n.bookingGuardTitle,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapH12,
                      Text(
                        context.l10n.bookingGuardSubtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapH32,
                      AppButton(
                        label: context.l10n.completeProfileCta,
                        icon: AppIcons.arrowForward,
                        onPressed: () => context.push('/complete-profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => (bookingCubit ?? getIt<BookingCubit>())
            ..initBooking(
              initialTripId: initialTripId,
              initialDirection: initialDirection,
              initialOriginStopId: initialOriginStopId,
              initialDestinationStopId: initialDestinationStopId,
            ),
          child: const _BookTripContent(),
        );
      },
    );
  }
}

class _BookTripContent extends StatelessWidget {
  const _BookTripContent();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return BlocConsumer<BookingCubit, BookingState>(
      listenWhen: (previous, current) {
        final hasNewError = current.errorMessage != null &&
            current.errorMessage!.isNotEmpty &&
            (current.errorMessage != previous.errorMessage ||
                previous.status != current.status);
        final hasNewAlert = current.autoTripAlert != null &&
            current.autoTripAlert!.isNotEmpty &&
            current.autoTripAlert != previous.autoTripAlert;
        return hasNewError || hasNewAlert;
      },
      listener: (context, state) {
        final cubit = context.read<BookingCubit>();

        if (state.autoTripAlert != null && state.autoTripAlert!.isNotEmpty) {
          AmomyFloatingAlert.show(
            context,
            title: state.autoTripAlert!,
            variant: AmomyAlertVariant.info,
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          String displayMessage = state.errorMessage!;
          if (displayMessage.contains('HOLD_EXPIRED')) {
            displayMessage = l10n.holdExpiredNotice;
          } else if (displayMessage.contains('SEAT_UNAVAILABLE') ||
              displayMessage.contains('SEAT_ALREADY_BOOKED') ||
              displayMessage.contains('SEAT_HELD_BY_ANOTHER_USER')) {
            displayMessage = l10n.seatUnavailableNotice;
          } else if (displayMessage.contains('INSUFFICIENT_POINTS') ||
              displayMessage.contains('INSUFFICIENT_UNEXPIRED_POINTS')) {
            displayMessage = l10n.insufficientPointsNotice;
          } else if (displayMessage.contains('PROFILE_INCOMPLETE')) {
            displayMessage = l10n.completeProfileToBook;
          } else if (displayMessage.contains('TODAY_ONLY_BOOKING')) {
            displayMessage = isAr
                ? 'الحجز متاح لرحلات اليوم فقط'
                : 'Booking is available for today only';
          } else if (displayMessage.contains('BOOKING_CLOSED')) {
            displayMessage = isAr
                ? 'تم إغلاق الحجز لهذه الرحلة'
                : 'Booking is closed for this trip';
          } else if (displayMessage.contains('ALREADY_BOOKED_TRIP') ||
              displayMessage.contains('already have an active booking') ||
              displayMessage.contains('AlreadyBookedTripFailure')) {
            displayMessage = isAr
                ? 'لقد قمت بحجز هذه الرحلة بالفعل'
                : 'You already have a booking for this trip';
          } else if (displayMessage.contains('PostgrestException') ||
              displayMessage.contains('Exception') ||
              displayMessage.contains('code:') ||
              displayMessage.contains('column') ||
              displayMessage.contains('seat_hold_status')) {
            displayMessage = l10n.errorOccurred;
          }

          AmomyFloatingAlert.show(
            context,
            title: displayMessage,
            variant: AmomyAlertVariant.error,
          );

          // Clear transient error so countdown timer ticks never re-trigger this alert
          cubit.clearError();
        }
      },
      builder: (context, state) {
        final cubit = context.read<BookingCubit>();

        if (state.currentStep == BookingStep.success &&
            state.confirmedBooking != null) {
          return AppScaffold(
            appBar: null,
            body: SafeArea(
              child: BookingSuccessView(booking: state.confirmedBooking!),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppAppBar(
            titleWidget: Text(
              _getTitleForStep(state.currentStep, l10n, isAr),
              style: const TextStyle(
                fontSize: 24,
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
                    onTap: () {
                      switch (state.currentStep) {
                        case BookingStep.setup:
                        case BookingStep.direction:
                          context.pop();
                          break;
                        case BookingStep.seatMap:
                          cubit.backToSetup();
                          break;
                        case BookingStep.review:
                          cubit.backToSeatMap();
                          break;
                        case BookingStep.success:
                          context.pop();
                          break;
                        case BookingStep.boardingStop:
                        case BookingStep.departureTime:
                          cubit.backToSetup();
                          break;
                      }
                    },
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        isAr
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        color: const Color(0xFF101828),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: state.currentStep == BookingStep.seatMap
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state.activeHold != null && state.selectedSeat != null
                      ? _SeatHoldBottomBanner(
                          key: ValueKey(state.selectedSeat!.seatId),
                          selectedSeat: state.selectedSeat!,
                          secondsRemaining: state.holdSecondsRemaining,
                          onProceed: cubit.proceedToReview,
                        )
                      : const SizedBox.shrink(),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SMART STEP 1: Smart Booking Setup (From, To, Trip)
                  if (state.currentStep == BookingStep.setup ||
                      state.currentStep == BookingStep.direction ||
                      state.currentStep == BookingStep.boardingStop ||
                      state.currentStep == BookingStep.departureTime) ...[
                    _SmartBookingSetupView(state: state, cubit: cubit),
                  ]
                  // STEP 2: Seat Selection
                  else if (state.currentStep == BookingStep.seatMap) ...[
                    if (state.status == BookingStatus.loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: AmomyBusLoading.medium(),
                      )
                    else
                      BusSeatMapWidget(
                        seats: state.seats,
                        selectedSeat: state.selectedSeat,
                        onSeatTap: (seat) => cubit.selectSeatAndHold(seat),
                      ),
                  ]
                  // STEP 3: Review & Confirm
                  else if (state.currentStep == BookingStep.review) ...[
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final walletBalance = (authState is Authenticated)
                            ? (authState.wallet?.availablePoints ??
                                      authState.wallet?.totalPoints ??
                                      0)
                                  .toDouble()
                            : 0.0;

                        return BookingReviewCard(
                          trip: state.selectedTrip!,
                          seat: state.selectedSeat!,
                          routeStop: state.selectedRouteStop,
                          destinationRouteStop: state.selectedDestinationStop,
                          userAvailablePoints: walletBalance,
                          isConfirming:
                              state.status == BookingStatus.confirming,
                          initialHoldSecondsRemaining:
                              state.holdSecondsRemaining,
                          onConfirm: cubit.confirmBooking,
                          onChooseSeatAgain: cubit.backToSeatMap,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTitleForStep(BookingStep step, dynamic l10n, bool isAr) {
    switch (step) {
      case BookingStep.setup:
      case BookingStep.direction:
      case BookingStep.boardingStop:
      case BookingStep.departureTime:
        return isAr ? 'احجز رحلتك' : 'Book a Ride';
      case BookingStep.seatMap:
        return l10n.selectSeat;
      case BookingStep.review:
        return isAr ? 'مراجعة الحجز' : 'Review Booking';
      case BookingStep.success:
        return l10n.bookingSuccessTitle;
    }
  }
}

class _SmartBookingSetupView extends StatelessWidget {
  final BookingState state;
  final BookingCubit cubit;

  const _SmartBookingSetupView({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    final canContinue =
        state.selectedRouteStop != null &&
        state.selectedDestinationStop != null &&
        state.selectedTrip != null &&
        state.selectedTrip!.availableSeatsCount > 0 &&
        (state.selectedDestinationStop!.stopOrder >
            state.selectedRouteStop!.stopOrder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. DIRECTION SWITCH (Sliding capsule)
        DirectionSelector(
          selectedDirection: state.selectedDirection,
          onDirectionChanged: (dir) => cubit.setDirection(dir),
        ),
        const SizedBox(height: 22),

        // 2. YOUR ROUTE (Connected From / To Component)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'مسارك' : 'Your Route',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            RouteStopSelector(
              selectedOrigin: state.selectedRouteStop,
              selectedDestination: state.selectedDestinationStop,
              originStops: state.routeStops,
              destinationStops: state.destinationStops,
              onOriginSelected: (s) => cubit.selectOriginStop(s),
              onDestinationSelected: (s) => cubit.selectDestinationStop(s),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 3. TODAY'S TRIPS / DEPARTURE TIME
        DepartureTimeSelector(
          trips: state.availableTrips,
          selectedTrip: state.selectedTrip,
          direction: state.selectedDirection,
          isTripLocked: state.isTripLocked,
          isLoading: state.status == BookingStatus.loading,
          onTripSelected: (t) => cubit.selectTrip(t),
        ),

        const SizedBox(height: 28),

        // 4. CONTINUE PRIMARY CTA
        _ContinueBookingButton(
          isEnabled: canContinue,
          label: isAr ? 'متابعة' : 'Continue',
          onPressed: () {
            if (canContinue) {
              cubit.proceedToSeatMap();
            } else {
              _validateAndAlert(context, isAr);
            }
          },
        ),
      ],
    );
  }

  void _validateAndAlert(BuildContext context, bool isAr) {
    String alertMsg = '';
    if (state.selectedRouteStop == null) {
      alertMsg = isAr
          ? 'يرجى اختيار محطة الركوب أولاً'
          : 'Please select your boarding stop first';
    } else if (state.selectedDestinationStop == null) {
      alertMsg = isAr
          ? 'يرجى اختيار محطة النزول'
          : 'Please select your destination stop';
    } else if (state.selectedDestinationStop!.stopOrder <=
        state.selectedRouteStop!.stopOrder) {
      alertMsg = isAr
          ? 'يجب أن تكون محطة النزول بعد محطة الركوب'
          : 'Destination must be after the boarding stop';
    } else if (state.selectedTrip == null) {
      alertMsg = isAr
          ? 'يرجى اختيار موعد الرحلة المناسب'
          : 'Please select a departure time';
    } else if (state.selectedTrip!.availableSeatsCount <= 0) {
      alertMsg = isAr
          ? 'هذه الرحلة ممتلئة، يرجى اختيار موعد آخر'
          : 'This trip is fully booked. Please choose another time.';
    }

    if (alertMsg.isNotEmpty) {
      AmomyFloatingAlert.show(
        context,
        title: alertMsg,
        variant: AmomyAlertVariant.warning,
      );
    }
  }
}

/// Primary Continue CTA with tactile micro-interaction scale feedback.
class _ContinueBookingButton extends StatefulWidget {
  final bool isEnabled;
  final String label;
  final VoidCallback onPressed;

  const _ContinueBookingButton({
    required this.isEnabled,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_ContinueBookingButton> createState() => _ContinueBookingButtonState();
}

class _ContinueBookingButtonState extends State<_ContinueBookingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return GestureDetector(
      onTapDown: (_) {
        if (!disableAnimations) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!disableAnimations) setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () {
        if (!disableAnimations) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.isEnabled
                ? AppColors.primary
                : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatHoldBottomBanner extends StatelessWidget {
  final TripSeat selectedSeat;
  final int secondsRemaining;
  final VoidCallback onProceed;

  const _SeatHoldBottomBanner({
    super.key,
    required this.selectedSeat,
    required this.secondsRemaining,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        border: const Border(
          top: BorderSide(color: Color(0xFFBAE6FD), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01589F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // 1. Seat icon / badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    selectedSeat.seatNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Seat Info & Remaining Hold Countdown
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'مقعد ${selectedSeat.seatNumber} مختار'
                          : 'Seat ${selectedSeat.seatNumber} selected',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C4A6E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAr ? 'محتجز لمدة $timeStr' : 'Held for $timeStr',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 3. Compact Continue CTA button
              ElevatedButton(
                onPressed: secondsRemaining > 0 ? onProceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr ? 'متابعة' : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isAr
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
