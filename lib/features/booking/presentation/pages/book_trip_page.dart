import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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
import '../widgets/departure_time_selector.dart';
import '../widgets/direction_selector.dart';
import '../widgets/service_date_selector.dart';

class BookTripPage extends StatelessWidget {
  final BookingCubit? bookingCubit;

  const BookTripPage({super.key, this.bookingCubit});

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
          create: (_) => (bookingCubit ?? getIt<BookingCubit>())..loadAvailableTrips(),
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

    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          String displayMessage = state.errorMessage!;
          if (displayMessage.contains('HOLD_EXPIRED')) {
            displayMessage = l10n.holdExpiredNotice;
          } else if (displayMessage.contains('SEAT_UNAVAILABLE') ||
              displayMessage.contains('SEAT_ALREADY_BOOKED')) {
            displayMessage = l10n.seatUnavailableNotice;
          } else if (displayMessage.contains('INSUFFICIENT_POINTS')) {
            displayMessage = l10n.insufficientPointsNotice;
          } else if (displayMessage.contains('PROFILE_INCOMPLETE')) {
            displayMessage = l10n.completeProfileToBook;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<BookingCubit>();

        if (state.currentStep == BookingStep.success && state.confirmedBooking != null) {
          return AppScaffold(
            appBar: AppAppBar(
              title: l10n.bookingSuccessTitle,
              showBackButton: false,
            ),
            body: SafeArea(
              child: BookingSuccessView(booking: state.confirmedBooking!),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppAppBar(
            title: _getTitleForStep(state.currentStep, l10n),
            showBackButton: true,
            onBackPressed: () {
              if (state.currentStep == BookingStep.review) {
                cubit.backToSeatMap();
              } else if (state.currentStep == BookingStep.seatMap) {
                cubit.backToTrips();
              } else {
                context.pop();
              }
            },
          ),
          bottomSheet: state.currentStep == BookingStep.seatMap && state.activeHold != null
              ? _HoldCountdownBanner(
                  secondsRemaining: state.holdSecondsRemaining,
                  onProceed: cubit.proceedToReview,
                )
              : null,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.currentStep == BookingStep.directionAndDate) ...[
                    // Step 1: Direction Selection
                    DirectionSelector(
                      selectedDirection: state.selectedDirection,
                      onDirectionChanged: cubit.setDirection,
                    ),
                    AppSpacing.gapH20,

                    // Step 2: Date Selection
                    ServiceDateSelector(
                      selectedDate: state.selectedDate,
                      onDateSelected: cubit.setDate,
                    ),
                    AppSpacing.gapH24,

                    // Step 3: Departure Times
                    if (state.status == BookingStatus.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      DepartureTimeSelector(
                        trips: state.availableTrips,
                        selectedTrip: state.selectedTrip,
                        onTripSelected: cubit.selectTrip,
                      ),
                  ] else if (state.currentStep == BookingStep.seatMap) ...[
                    // Step 4: Seat Selection
                    if (state.status == BookingStatus.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Trip summary header
                      _TripHeaderSnippet(trip: state.selectedTrip!),
                      AppSpacing.gapH20,

                      // 2D Bus Seat Map
                      BusSeatMapWidget(
                        seats: state.seats,
                        selectedSeat: state.selectedSeat,
                        onSeatTap: (seat) => cubit.selectSeatAndHold(seat),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ] else if (state.currentStep == BookingStep.review) ...[
                    // Step 5: Review & Confirmation
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final walletBalance = (authState is Authenticated)
                            ? (authState.wallet?.availablePoints ?? authState.wallet?.totalPoints ?? 0).toDouble()
                            : 0.0;

                        return BookingReviewCard(
                          trip: state.selectedTrip!,
                          seat: state.selectedSeat!,
                          userAvailablePoints: walletBalance,
                          isConfirming: state.status == BookingStatus.confirming,
                          onConfirm: cubit.confirmBooking,
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

  String _getTitleForStep(BookingStep step, dynamic l10n) {
    switch (step) {
      case BookingStep.directionAndDate:
      case BookingStep.timeSelection:
        return l10n.bookRideTitle;
      case BookingStep.seatMap:
        return l10n.selectSeat;
      case BookingStep.review:
        return l10n.reviewBooking;
      case BookingStep.success:
        return l10n.bookingSuccessTitle;
    }
  }
}

class _TripHeaderSnippet extends StatelessWidget {
  final TripOption trip;

  const _TripHeaderSnippet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(AppIcons.clock, size: 18, color: AppColors.primary),
              AppSpacing.gapW8,
              Text(
                trip.departureTime,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '${trip.originName(locale)} → ${trip.destinationName(locale)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldCountdownBanner extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onProceed;

  const _HoldCountdownBanner({
    required this.secondsRemaining,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      AppSpacing.gapW8,
                      Text(
                        l10n.holdCountdown(timeStr),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapW16,
            ElevatedButton(
              onPressed: secondsRemaining > 0 ? onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.next,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapW8,
                  const Icon(AppIcons.arrowForward, size: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
