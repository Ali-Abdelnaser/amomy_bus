import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking_entities.dart';

class BusSeatMapWidget extends StatelessWidget {
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final ValueChanged<TripSeat> onSeatTap;

  const BusSeatMapWidget({
    super.key,
    required this.seats,
    required this.selectedSeat,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Group seats by rowIndex
    final rowsMap = <int, List<TripSeat>>{};
    for (final seat in seats) {
      rowsMap.putIfAbsent(seat.rowIndex, () => []).add(seat);
    }
    final sortedRowIndices = rowsMap.keys.toList()..sort();

    return Column(
      children: [
        // 1. Front of the bus / Driver indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.airline_seat_recline_extra,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapW8,
                  Text(
                    l10n.driverFront,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),

        // 2. Bus Body Container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            border: const Border(
              left: BorderSide(color: AppColors.border, width: 2),
              right: BorderSide(color: AppColors.border, width: 2),
              bottom: BorderSide(color: AppColors.border, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: sortedRowIndices.map((rowIndex) {
              final rowSeats = rowsMap[rowIndex]!;
              rowSeats.sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildRowSeats(rowSeats),
                ),
              );
            }).toList(),
          ),
        ),

        AppSpacing.gapH20,

        // 3. Legend
        _buildLegend(l10n),
      ],
    );
  }

  List<Widget> _buildRowSeats(List<TripSeat> rowSeats) {
    if (rowSeats.length <= 3) {
      final leftSeat = rowSeats.firstWhere(
        (s) => s.columnIndex == 0,
        orElse: () => rowSeats.first,
      );
      final rightSeats = rowSeats.where((s) => s.columnIndex > 0).toList();

      return [
        _SeatBox(
          seat: leftSeat,
          isSelected: selectedSeat?.seatId == leftSeat.seatId,
          onTap: () => onSeatTap(leftSeat),
        ),
        const SizedBox(width: 36),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: rightSeats.map((s) {
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _SeatBox(
                seat: s,
                isSelected: selectedSeat?.seatId == s.seatId,
                onTap: () => onSeatTap(s),
              ),
            );
          }).toList(),
        ),
      ];
    } else {
      return rowSeats.map((s) {
        return _SeatBox(
          seat: s,
          isSelected: selectedSeat?.seatId == s.seatId,
          onTap: () => onSeatTap(s),
        );
      }).toList();
    }
  }

  Widget _buildLegend(dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _LegendItem(
            color: AppColors.primary,
            label: l10n.seatStatusAvailable,
          ),
          _LegendItem(
            color: AppColors.accentYellow,
            label: l10n.seatStatusSelected,
          ),
          _LegendItem(
            color: Colors.orange,
            label: l10n.seatStatusHeld,
          ),
          _LegendItem(
            color: AppColors.success,
            label: l10n.seatStatusBooked,
          ),
        ],
      ),
    );
  }
}

class _SeatBox extends StatelessWidget {
  final TripSeat seat;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeatBox({
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      bgColor = AppColors.accentYellow;
      textColor = AppColors.textPrimary;
      borderColor = AppColors.accentYellow;
    } else if (seat.isMine) {
      bgColor = AppColors.accentYellow;
      textColor = AppColors.textPrimary;
      borderColor = AppColors.accentYellow;
    } else if (seat.isHeld) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      borderColor = Colors.orange.shade300;
    } else if (seat.isBooked) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      borderColor = AppColors.success.withValues(alpha: 0.3);
    } else {
      bgColor = AppColors.primaryLight;
      textColor = AppColors.primary;
      borderColor = AppColors.primary.withValues(alpha: 0.3);
    }

    final isTappable = seat.isAvailable || seat.isMine || isSelected;

    return InkWell(
      onTap: isTappable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.seat,
              size: 16,
              color: textColor,
            ),
            const SizedBox(height: 2),
            Text(
              seat.seatNumber,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 11,
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
  final String label;

  const _LegendItem({
    required this.color,
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
          ),
        ),
        AppSpacing.gapW8,
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
