import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../trips/presentation/cubit/passenger_trips_cubit.dart';
import '../../../trips/presentation/cubit/passenger_trips_state.dart';

class HomeUpcomingTripSection extends StatelessWidget {
  final PassengerTripsCubit? tripsCubit;

  const HomeUpcomingTripSection({super.key, this.tripsCubit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) =>
          (tripsCubit ??
          (getIt.isRegistered<PassengerTripsCubit>()
              ? (getIt<PassengerTripsCubit>()..loadBookings())
              : PassengerTripsCubit.idle())),
      child: BlocBuilder<PassengerTripsCubit, PassengerTripsState>(
        builder: (context, state) {
          final upcoming = state.nearestUpcomingTrip;
          final locale = Localizations.localeOf(context).languageCode;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
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
                    onTap: () => context.go('/trips'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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

              if (upcoming != null)
                AppCard(
                  padding: AppSpacing.edgeInsetsA16,
                  backgroundColor: Colors.white,
                  border: const BorderSide(color: AppColors.border),
                  onTap: () => context.go('/trips'),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${upcoming.originName(locale)} → ${upcoming.destinationName(locale)}',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.bookingStatusConfirmed,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                AppIcons.calendar,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                "${upcoming.serviceDate.year}-${upcoming.serviceDate.month.toString().padLeft(2, '0')}-${upcoming.serviceDate.day.toString().padLeft(2, '0')}",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                AppIcons.clock,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                AppTimeFormatter.formatPassengerBooking(
                                  upcoming,
                                  locale: locale,
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                AppIcons.seat,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                upcoming.seatNumber,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                // Empty state card
                AppCard(
                  padding: AppSpacing.edgeInsetsA20,
                  backgroundColor: AppColors.surfaceSoft,
                  border: const BorderSide(color: AppColors.border),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.emptyUpcomingTrip,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                      AppSpacing.gapH12,
                      Text(
                        l10n.noUpcomingTrip,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapH16,
                      AppButton(
                        label: state.shouldDisableBookingEntry
                            ? (locale.startsWith('ar')
                                  ? 'الحجز مغلق'
                                  : 'Booking closed')
                            : l10n.bookTripCta,
                        icon: state.shouldDisableBookingEntry
                            ? null
                            : AppIcons.ticket,
                        variant: AppButtonVariant.outline,
                        height: 38,
                        onPressed: state.shouldDisableBookingEntry
                            ? null
                            : () => context.push('/book-trip'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
