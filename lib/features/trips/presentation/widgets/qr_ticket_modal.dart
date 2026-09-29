import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';
import '../../../shell/presentation/widgets/nav_svg_icon.dart';
import '../cubit/passenger_trips_cubit.dart';
import '../cubit/passenger_trips_state.dart';

class QrTicketItem {
  final String? bookingId;
  final String departureTime;
  final String originName;
  final String destinationName;
  final String seatNumber;
  final double farePoints;
  final String qrToken;
  final bool isExtraSeat;

  const QrTicketItem({
    this.bookingId,
    required this.departureTime,
    required this.originName,
    required this.destinationName,
    required this.seatNumber,
    required this.farePoints,
    required this.qrToken,
    this.isExtraSeat = false,
  });

  factory QrTicketItem.fromBooking(
    PassengerBooking booking, {
    String? locale,
    bool isExtraSeat = false,
  }) {
    final lang = locale ?? 'ar';
    return QrTicketItem(
      bookingId: booking.id,
      departureTime: AppTimeFormatter.formatPassengerBooking(
        booking,
        locale: lang,
      ),
      originName: booking.originName(lang),
      destinationName: booking.destinationName(lang),
      seatNumber: booking.seatNumber,
      farePoints: booking.farePoints,
      qrToken: booking.qrToken,
      isExtraSeat: isExtraSeat,
    );
  }
}

class QrTicketModal extends StatefulWidget {
  final List<QrTicketItem> tickets;
  final int initialIndex;

  QrTicketModal({
    super.key,
    List<QrTicketItem>? tickets,
    this.initialIndex = 0,
    String? bookingId,
    String departureTime = '',
    String originName = '',
    String destinationName = '',
    String seatNumber = '',
    double farePoints = 0,
    String qrToken = '',
  }) : tickets = tickets ??
            [
              QrTicketItem(
                bookingId: bookingId,
                departureTime: departureTime,
                originName: originName,
                destinationName: destinationName,
                seatNumber: seatNumber,
                farePoints: farePoints,
                qrToken: qrToken,
              ),
            ];

  static void show(
    BuildContext context, {
    List<QrTicketItem>? tickets,
    int initialIndex = 0,
    String? bookingId,
    String? departureTime,
    String? originName,
    String? destinationName,
    String? seatNumber,
    double? farePoints,
    String? qrToken,
  }) {
    PassengerTripsCubit? tripsCubit;
    try {
      tripsCubit = context.read<PassengerTripsCubit>();
    } catch (_) {}

    final effectiveTickets = (tickets != null && tickets.isNotEmpty)
        ? tickets
        : [
            QrTicketItem(
              bookingId: bookingId,
              departureTime: departureTime ?? '',
              originName: originName ?? '',
              destinationName: destinationName ?? '',
              seatNumber: seatNumber ?? '',
              farePoints: farePoints ?? 0,
              qrToken: qrToken ?? '',
            ),
          ];

    showModalBottomSheet(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (modalContext) {
        final content = QrTicketModal(
          tickets: effectiveTickets,
          initialIndex: initialIndex,
        );

        if (tripsCubit != null) {
          final targetBookingIds = effectiveTickets
              .map((t) => t.bookingId)
              .whereType<String>()
              .toSet();

          if (targetBookingIds.isNotEmpty) {
            return BlocProvider.value(
              value: tripsCubit,
              child: BlocListener<PassengerTripsCubit, PassengerTripsState>(
                listenWhen: (prev, curr) {
                  final allCheckedIn = targetBookingIds.every((id) {
                    final isHistoryCheckedIn = curr.historyTrips.any(
                      (b) => b.id == id && b.checkedInAt != null,
                    );
                    final isTodayCheckedIn = curr.todayTrips.any(
                      (t) =>
                          (t.bookingId == id ||
                              t.bookings.any((b) => b.id == id)) &&
                          t.isCheckedIn,
                    );
                    final isRemovedFromUpcoming = !curr.upcomingTrips.any(
                      (b) => b.id == id,
                    );
                    return isHistoryCheckedIn ||
                        isTodayCheckedIn ||
                        isRemovedFromUpcoming;
                  });
                  return allCheckedIn;
                },
                listener: (ctx, state) {
                  if (Navigator.of(modalContext).canPop()) {
                    Navigator.of(modalContext).pop();
                  }
                },
                child: content,
              ),
            );
          }
        }

        return content;
      },
    );
  }

  @override
  State<QrTicketModal> createState() => _QrTicketModalState();
}

class _QrTicketModalState extends State<QrTicketModal> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.tickets.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.tickets.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final currentTicket = widget.tickets.isNotEmpty
        ? widget.tickets[_currentIndex]
        : const QrTicketItem(
            departureTime: '',
            originName: '',
            destinationName: '',
            seatNumber: '—',
            farePoints: 0,
            qrToken: '',
          );

    return AmomySheetContainer(
      hasBottomNav: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Title + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.tickets.length > 1
                      ? (isAr
                          ? 'تذاكر الصعود الإلكترونية (${widget.tickets.length})'
                          : 'Digital Boarding Tickets (${widget.tickets.length})')
                      : (isAr
                          ? 'تذكرة الصعود الإلكترونية'
                          : 'Digital Boarding Ticket'),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.gapH12,

            // Multi-ticket seat selector tabs
            if (widget.tickets.length > 1) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(widget.tickets.length, (index) {
                    final item = widget.tickets[index];
                    final isSelected = index == _currentIndex;
                    final isExtra = item.isExtraSeat || index > 0;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentIndex = index),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NavSvgIcon(
                                type: NavSvgType.trip,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'مقعد ${item.seatNumber}${isExtra ? " (إضافي)" : ""}'
                                      : 'Seat ${item.seatNumber}${isExtra ? " (Extra)" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],

            // QR Ticket Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  AppQrTicketWidget(data: currentTicket.qrToken, size: 180),
                  AppSpacing.gapH12,
                  Text(
                    widget.tickets.length > 1
                        ? (isAr
                            ? 'رمز صعود خاص بمقعد ${currentTicket.seatNumber} فقط — أظهره للسائق'
                            : 'Dedicated QR for Seat ${currentTicket.seatNumber} only — show upon boarding')
                        : (isAr
                            ? 'أظهر هذا الرمز للسائق عند الصعود'
                            : 'Show this QR code to the driver upon boarding'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppSpacing.gapH14,

            // Trip Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TicketDetailItem(
                  icon: AppIcons.clock,
                  label: isAr ? 'الموعد' : 'Time',
                  value: AppTimeFormatter.formatDepartureTime(
                    departureTime: currentTicket.departureTime,
                    isArabic: isAr,
                  ),
                ),
                _TicketDetailItem(
                  icon: AppIcons.seat,
                  label: isAr ? 'المقعد' : 'Seat',
                  value: currentTicket.seatNumber,
                ),
                _TicketDetailItem(
                  icon: AppIcons.ticket,
                  label: isAr ? 'القيمة' : 'Fare',
                  value:
                      '${currentTicket.farePoints.toInt()} ${isAr ? "نقطة" : "pts"}',
                ),
              ],
            ),
            AppSpacing.gapH12,

            // From -> To Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      currentTicket.originName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isAr
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      currentTicket.destinationName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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

class _TicketDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TicketDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
