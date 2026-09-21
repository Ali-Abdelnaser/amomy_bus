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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/booking_entities.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/booking_mode_toggle.dart';
import '../widgets/booking_review_card.dart';
import '../widgets/booking_success_view.dart';
import '../widgets/bus_seat_map_widget.dart';
import '../widgets/departure_time_selector.dart';
import '../widgets/direction_selector.dart';
import '../widgets/return_meeting_info_card.dart';
import '../widgets/round_trip_return_time_selector.dart';
import '../widgets/route_stop_selector.dart';

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
                        icon: context.isRtl
                            ? AppIcons.arrowBack
                            : AppIcons.arrowForward,
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

class _BookTripContent extends StatefulWidget {
  const _BookTripContent();

  @override
  State<_BookTripContent> createState() => _BookTripContentState();
}

class _BookTripContentState extends State<_BookTripContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BookingCubit>().resyncHoldOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return BlocConsumer<BookingCubit, BookingState>(
      listenWhen: (previous, current) {
        final hasNewError =
            current.errorMessage != null &&
            current.errorMessage!.isNotEmpty &&
            (current.errorMessage != previous.errorMessage ||
                previous.status != current.status);
        final hasNewAlert =
            current.autoTripAlert != null &&
            current.autoTripAlert!.isNotEmpty &&
            current.autoTripAlert != previous.autoTripAlert;
        return hasNewError || hasNewAlert;
      },
      listener: (context, state) {
        final cubit = context.read<BookingCubit>();

        if (state.autoTripAlert != null && state.autoTripAlert!.isNotEmpty) {
          AppSnackBar.showInfo(
            context,
            state.autoTripAlert!,
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppSnackBar.showError(
            context,
            state.errorMessage,
          );

          cubit.clearError();
        }
      },
      builder: (context, state) {
        final cubit = context.read<BookingCubit>();

        if (state.currentStep == BookingStep.success) {
          if (state.confirmedBundle != null) {
            return AppScaffold(
              appBar: null,
              body: SafeArea(
                child: BookingSuccessView(
                  bundleConfirmation: state.confirmedBundle!,
                ),
              ),
            );
          } else if (state.confirmedBooking != null) {
            return AppScaffold(
              appBar: null,
              body: SafeArea(
                child: BookingSuccessView(booking: state.confirmedBooking!),
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppAppBar(
            titleWidget: Text(
              _getTitleForStep(state, l10n, isAr),
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
                          if (state.isRoundTrip &&
                              state.roundTripSeatStep ==
                                  RoundTripSeatStep.returnSeat) {
                            cubit.backToOutboundSeatMap();
                          } else {
                            cubit.backToSetup();
                          }
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
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
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
                  child: _buildSeatHoldBottomBanner(state, cubit, isAr),
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
                  // STEP 2: Seat Selection (Outbound Seat or Return Seat)
                  else if (state.currentStep == BookingStep.seatMap) ...[
                    if (state.status == BookingStatus.loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: AmomyBusLoading.medium(),
                      )
                    else if (state.isRoundTrip &&
                        state.roundTripSeatStep == RoundTripSeatStep.returnSeat)
                      BusSeatMapWidget(
                        seats: state.returnSeats,
                        selectedSeat: state.selectedReturnSeat,
                        onSeatTap: (seat) => cubit.selectSeatAndHold(seat),
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
                          bundleHold: state.bundleHold,
                          returnSeat: state.selectedReturnSeat,
                          returnOption: state.selectedReturnOption,
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

  Widget _buildSeatHoldBottomBanner(
    BookingState state,
    BookingCubit cubit,
    bool isAr,
  ) {
    if (state.isSingle) {
      if (state.activeHold != null && state.selectedSeat != null) {
        return _SeatHoldBottomBanner(
          key: ValueKey('single_${state.selectedSeat!.seatId}'),
          selectedSeat: state.selectedSeat!,
          secondsRemaining: state.holdSecondsRemaining,
          onProceed: cubit.proceedToReview,
          buttonLabel: isAr ? 'متابعة' : 'Continue',
        );
      }
      return const SizedBox.shrink();
    } else {
      // Round Trip
      if (state.roundTripSeatStep == RoundTripSeatStep.outbound) {
        if (state.bundleHold != null && state.selectedSeat != null) {
          return _SeatHoldBottomBanner(
            key: ValueKey('bundle_outbound_${state.selectedSeat!.seatId}'),
            selectedSeat: state.selectedSeat!,
            secondsRemaining: state.holdSecondsRemaining,
            onProceed: cubit.proceedToReturnSeatMap,
            buttonLabel: isAr ? 'مقعد العودة' : 'Return Seat',
          );
        }
      } else {
        // Return seat step
        if (state.bundleHold != null && state.selectedReturnSeat != null) {
          return _SeatHoldBottomBanner(
            key: ValueKey('bundle_return_${state.selectedReturnSeat!.seatId}'),
            selectedSeat: state.selectedReturnSeat!,
            secondsRemaining: state.holdSecondsRemaining,
            onProceed: cubit.proceedToReview,
            buttonLabel: isAr ? 'مراجعة الحجز' : 'Review',
          );
        }
      }
      return const SizedBox.shrink();
    }
  }

  String _getTitleForStep(BookingState state, dynamic l10n, bool isAr) {
    switch (state.currentStep) {
      case BookingStep.setup:
      case BookingStep.direction:
      case BookingStep.boardingStop:
      case BookingStep.departureTime:
        return isAr ? 'احجز رحلتك' : 'Book a Ride';
      case BookingStep.seatMap:
        if (state.isRoundTrip) {
          return state.roundTripSeatStep == RoundTripSeatStep.returnSeat
              ? (isAr ? 'اختر مقعد العودة' : 'Select Return Seat')
              : (isAr ? 'اختر مقعد الذهاب' : 'Select Outbound Seat');
        }
        return l10n.selectSeat;
      case BookingStep.review:
        return isAr ? 'مراجعة الحجز' : 'Review Booking';
      case BookingStep.success:
        return isAr && state.isRoundTrip
            ? 'تم حجز الذهاب والعودة بنجاح'
            : l10n.bookingSuccessTitle;
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

    final isRoundTrip = state.isRoundTrip;
    final canContinueSingle =
        state.selectedRouteStop != null &&
        state.selectedDestinationStop != null &&
        state.selectedTrip != null &&
        state.selectedTrip!.canBook &&
        (state.selectedDestinationStop!.stopOrder >
            state.selectedRouteStop!.stopOrder);

    final canContinueRoundTrip =
        canContinueSingle &&
        state.selectedReturnOption != null &&
        state.selectedReturnOption!.isBookable;

    final canContinue = isRoundTrip ? canContinueRoundTrip : canContinueSingle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. DIRECTION SWITCH (Sliding capsule)
        DirectionSelector(
          selectedDirection: state.selectedDirection,
          onDirectionChanged: (dir) => cubit.setDirection(dir),
        ),

        // 1.1 BOOKING MODE SELECTOR (Single / Round Trip - 15% discount)
        // Offered ONLY when booking direction is Outbound
        if (state.selectedDirection == BookingDirection.outbound) ...[
          const SizedBox(height: 12),
          BookingModeToggle(
            mode: state.bookingMode,
            onModeChanged: (mode) => cubit.setBookingMode(mode),
          ),
        ],

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

        // 3. TODAY'S OUTBOUND TRIPS / DEPARTURE TIME
        DepartureTimeSelector(
          trips: state.availableTrips,
          selectedTrip: state.selectedTrip,
          direction: state.selectedDirection,
          isTripLocked: state.isTripLocked,
          isLoading: state.status == BookingStatus.loading,
          onTripSelected: (t) => cubit.selectTrip(t),
        ),

        // 3.0 RETURN MEETING INFO (In Single Return Mode)
        if (state.selectedDirection == BookingDirection.returnTrip &&
            state.availableTrips.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReturnMeetingInfoCard(selectedTrip: state.selectedTrip),
        ],

        // 3.1 TODAY'S RETURN TRIPS (In Round Trip Mode)
        if (isRoundTrip) ...[
          const SizedBox(height: 22),
          RoundTripReturnTimeSelector(
            returnOptions: state.returnOptions,
            selectedReturnOption: state.selectedReturnOption,
            isLoading: state.isLoadingRoundTripReturnOptions,
            errorMessage: state.roundTripReturnOptionsError,
            onRetry: () => cubit.loadRoundTripReturnOptions(),
            onOptionSelected: (o) => cubit.selectReturnOption(o),
          ),
        ],

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
          ? 'يرجى اختيار موعد رحلة الذهاب المناسب'
          : 'Please select an outbound departure time';
    } else if (!state.selectedTrip!.canBook) {
      alertMsg = isAr
          ? 'رحلة الذهاب غير متاحة للحجز، يرجى اختيار موعد آخر'
          : 'This outbound trip is not available. Please choose another time.';
    } else if (state.isRoundTrip &&
        (state.selectedReturnOption == null ||
            !state.selectedReturnOption!.isBookable)) {
      alertMsg = isAr
          ? 'يرجى اختيار موعد رحلة العودة المناسب'
          : 'Please select a return departure time';
    }

    if (alertMsg.isNotEmpty) {
      AppSnackBar.showWarning(
        context,
        alertMsg,
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
  final String? buttonLabel;

  const _SeatHoldBottomBanner({
    super.key,
    required this.selectedSeat,
    required this.secondsRemaining,
    required this.onProceed,
    this.buttonLabel,
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
                      buttonLabel ?? (isAr ? 'متابعة' : 'Continue'),
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
