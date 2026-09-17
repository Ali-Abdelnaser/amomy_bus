import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';
import '../../../tracking/presentation/cubit/tracking_cubit.dart';
import '../../../tracking/presentation/cubit/tracking_state.dart';
import '../../domain/entities/home_summary.dart';

/// The enriched mini travel ticket view of the upcoming booking on Home.
class HomeUpcomingTripCard extends StatelessWidget {
  final PassengerUpcomingTrip? upcomingTrip;
  final bool isBookingAvailable;
  final bool hasLoadedAvailability;
  final VoidCallback? onCancelBooking;

  const HomeUpcomingTripCard({
    super.key,
    this.upcomingTrip,
    this.isBookingAvailable = true,
    this.hasLoadedAvailability = false,
    this.onCancelBooking,
  });

  bool _isCancellationAvailable(
    PassengerUpcomingTrip trip,
    TrackingState? trackingState,
  ) {
    final isTrackedTrip =
        trackingState?.summary?.activeTripId == trip.tripId ||
        trackingState?.trackedTripId == trip.tripId;
    return !(isTrackedTrip && (trackingState?.isLive ?? false));
  }

  void _showTicket(BuildContext context, PassengerUpcomingTrip trip) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(
      context,
    ).languageCode.startsWith('ar');

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => AmomySheetContainer(
        hasBottomNav: true,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qrTicketInstruction,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH16,
            AppQrTicketWidget(data: trip.qrToken, size: 180),
            AppSpacing.gapH16,
            Text(
              AppTimeFormatter.formatUpcomingTrip(trip, isArabic: isArabic),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.gapH16,
            AppButton(
              label: l10n.dismiss,
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trip = upcomingTrip;
    TrackingState? trackingState;
    try {
      trackingState = context.watch<TrackingCubit>().state;
    } catch (_) {
      trackingState = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.upcomingTrip,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        AppSpacing.gapH12,
        if (trip == null)
          _EmptyUpcomingTrip(
            isBookingAvailable: isBookingAvailable,
            hasLoadedAvailability: hasLoadedAvailability,
          )
        else
          _BookedUpcomingTrip(
            trip: trip,
            canCancel: _isCancellationAvailable(trip, trackingState),
            onShowQr: () => _showTicket(context, trip),
            onCancel: onCancelBooking ?? () => context.go(RoutePaths.trips),
          ),
      ],
    );
  }
}

/// Centered vertical composition with illustration above text and full CTA button.
class _EmptyUpcomingTrip extends StatelessWidget {
  final bool isBookingAvailable;
  final bool hasLoadedAvailability;

  const _EmptyUpcomingTrip({
    required this.isBookingAvailable,
    required this.hasLoadedAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canBook = !hasLoadedAvailability || isBookingAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.emptyUpcomingTrip,
            width: 82,
            height: 82,
            fit: BoxFit.contain,
          ),
          AppSpacing.gapH14,
          Text(
            l10n.noUpcomingTrip,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH6,
          Text(
            l10n.noUpcomingTripSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (canBook) ...[
            AppSpacing.gapH18,
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 148),
              child: AppButton(
                key: const Key('home-upcoming-book-now'),
                label: l10n.bookNow,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                onPressed: () => context.push(RoutePaths.bookTrip),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A mini travel ticket with enriched information hierarchy:
/// Confirmed status, seat badge, localized day/date, direction, large departure hero,
/// boarding stop, fare points, ticket perforation, and balanced actions.
class _BookedUpcomingTrip extends StatelessWidget {
  final PassengerUpcomingTrip trip;
  final bool canCancel;
  final VoidCallback onShowQr;
  final VoidCallback onCancel;

  const _BookedUpcomingTrip({
    required this.trip,
    required this.canCancel,
    required this.onShowQr,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(
      context,
    ).languageCode.startsWith('ar');
    final l10n = context.l10n;
    final localeCode = isArabic ? 'ar' : 'en';

    // Localized date (e.g. Thu, 17 Sep / الخميس، 17 سبتمبر)
    final formattedDate = DateFormat(
      'EEE, d MMM',
      localeCode,
    ).format(trip.departureAt);

    // Direction label
    final directionLabel = trip.direction.toLowerCase() == 'outbound'
        ? l10n.directionOutbound
        : l10n.directionReturn;

    // Boarding stop display name (if available)
    final boardingStop = trip.boardingStopDisplayName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP ROW: Confirmed Status + Seat Number Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                // Confirmed Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.gapW6,
                      Text(
                        l10n.bookingStatusConfirmed,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF027A48),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Assigned Seat Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.seat,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapW6,
                      Text(
                        l10n.seatNumberLabel(trip.seatNumber),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. SECONDARY META: Localized Day/Date • Direction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$formattedDate • $directionLabel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),
          ),

          AppSpacing.gapH8,

          // 3. PRIMARY HERO: Large Departure Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              AppTimeFormatter.formatUpcomingTrip(trip, isArabic: isArabic),
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: -0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          AppSpacing.gapH10,

          // 4. SUPPORTING INFO: Boarding Stop (if available) & Fare Points Paid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (boardingStop != null && boardingStop.isNotEmpty) ...[
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.location,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        AppSpacing.gapW4,
                        Flexible(
                          child: Text(
                            boardingStop,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF8E8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF9E4B7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.ticket,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                      AppSpacing.gapW4,
                      Text(
                        '${trip.farePoints} ${l10n.pointsUnit}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFB54708),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapH14,

          // 5. Ticket Perforation Line with edge notches
          const _TicketPerforationLine(),

          // 6. ACTION ROW: [ QR ] & [ Cancel ]
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.qr,
                    icon: const Icon(
                      AppIcons.qrCode,
                      size: 18,
                      color: Colors.white,
                    ),
                    height: 46,
                    isFullWidth: true,
                    onPressed: onShowQr,
                  ),
                ),
                if (canCancel) ...[
                  AppSpacing.gapW12,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(AppIcons.close, size: 16),
                      label: Text(
                        l10n.cancel,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        backgroundColor: const Color(0xFFFEF3F2),
                        side: const BorderSide(
                          color: Color(0xFFFECDCA),
                          width: 1.2,
                        ),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A subtle, authentic transit perforation line dividing the boarding pass header from actions.
class _TicketPerforationLine extends StatelessWidget {
  const _TicketPerforationLine();

  @override
  Widget build(BuildContext context) {
    final notchColor = Theme.of(context).scaffoldBackgroundColor;

    return Row(
      children: [
        // Left notch
        Container(
          width: 8,
          height: 16,
          decoration: BoxDecoration(
            color: notchColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0)),
              right: BorderSide(color: Color(0xFFE2E8F0)),
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        // Dashed line
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dashWidth = 5.0;
                const dashSpace = 4.0;
                final dashCount =
                    (constraints.maxWidth / (dashWidth + dashSpace)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => const SizedBox(
                      width: dashWidth,
                      height: 1.2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Right notch
        Container(
          width: 8,
          height: 16,
          decoration: BoxDecoration(
            color: notchColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0)),
              left: BorderSide(color: Color(0xFFE2E8F0)),
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}
