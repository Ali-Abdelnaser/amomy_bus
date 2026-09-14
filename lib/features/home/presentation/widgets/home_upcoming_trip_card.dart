import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';
import '../../domain/entities/home_summary.dart';

class HomeUpcomingTripCard extends StatelessWidget {
  final PassengerUpcomingTrip? upcomingTrip;

  const HomeUpcomingTripCard({
    super.key,
    this.upcomingTrip,
  });

  void _showTicketModal(BuildContext context, PassengerUpcomingTrip trip) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    showModalBottomSheet<void>(
      context: context,
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
                AppQrTicketWidget(
                  data: trip.qrToken,
                  size: 180,
                ),
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
                        value: trip.departureTime,
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
    final trip = upcomingTrip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        if (trip != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarker.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Ticket Header: Status, Direction, and Supporting Bus Detail
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSoft,
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppSpacing.gapW6,
                            Text(
                              l10n.bookingStatusConfirmed,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),

                        // Direction Tag + Supporting Bus Icon Detail
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AmomyBusIcon(
                              size: 15,
                              color: AppColors.primary,
                            ),
                            AppSpacing.gapW6,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
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
                      ],
                    ),
                  ),

                  // 2. Ticket Body: Departure Time Hero + Route Timeline (Boarding Stop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Route timeline with boarding stop and destination
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.stopNameAr != null &&
                                                  trip.stopNameAr!.isNotEmpty
                                              ? trip.stopNameAr!
                                              : trip.originName(locale),
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (trip.stopNameAr != null &&
                                            trip.stopNameAr!.isNotEmpty)
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
                                padding:
                                    const EdgeInsetsDirectional.only(start: 3.5),
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
                                      trip.destinationName(locale),
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

                        // Hero Departure Time Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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
                                trip.departureTime,
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

                  // 3. Ticket Perforated Divider with Edge Cut-out Notches
                  const _TicketPerforatedDivider(),

                  // 4. Ticket Footer: Compact Chips (Date, Seat, Fare) & View Ticket Action
                  Container(
                    color: AppColors.surfaceSoft,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        // Compact Chips Row
                        Row(
                          children: [
                            Expanded(
                              child: _TicketMetaChip(
                                icon: AppIcons.calendar,
                                label:
                                    "${trip.serviceDate.year}-${trip.serviceDate.month.toString().padLeft(2, '0')}-${trip.serviceDate.day.toString().padLeft(2, '0')}",
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

                        // View Ticket (QR Pass) CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () => _showTicketModal(context, trip),
                            icon: const Icon(AppIcons.qrCode,
                                size: 16, color: AppColors.primary),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Ticket-inspired clean empty stub
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
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
                    child: AmomyBusIcon(
                      size: 20,
                      color: AppColors.primary,
                    ),
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
                        l10n.bookRideSubtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapW10,
                ElevatedButton(
                  onPressed: () => context.push('/book-trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.bookTripCta,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
                final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
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

  const _TicketMetaChip({
    required this.icon,
    required this.label,
  });

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
