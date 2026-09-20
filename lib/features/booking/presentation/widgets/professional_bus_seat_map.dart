import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/models/bus_seat_layout.dart';
import 'bus_interior_base_painter.dart';
import 'bus_seat_visual.dart';

/// Interactive top-view 28-seat physical bus map.
///
/// Features:
/// - Authoritative 28-passenger physical bus layout (1 front + 12 left + 10 right + 5 rear).
/// - Non-interactive vector chassis canvas (driver, door/stairs, windshield, aisle).
/// - Responsive normalized coordinate positioning ([BusSeatSlot.x], [BusSeatSlot.y]).
/// - Independent interactive [BusSeatVisual] widgets with scale micro-animations.
/// - Unmapped slots gracefully styled as [SeatVisualState.unconfigured].
class ProfessionalBusSeatMap extends StatelessWidget {
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final ValueChanged<TripSeat> onSeatTap;

  /// Aspect ratio for the bus canvas (width : height).
  /// Matches canonical 320 / 680 (~0.47) for realistic coach proportions.
  final double aspectRatio;

  /// Debug-only visual preview flag.
  /// Strictly guarded by [kDebugMode].
  /// In RELEASE / PROFILE: automatically treated as false regardless of this parameter.
  /// When active (debug only): unconfigured physical slots render with synthetic preview styling
  /// to verify complete 28-seat interior layout, but MUST remain non-bookable.
  final bool showFullLayoutPreview;

  const ProfessionalBusSeatMap({
    super.key,
    required this.seats,
    required this.selectedSeat,
    required this.onSeatTap,
    this.aspectRatio = 320.0 / 680.0,
    this.showFullLayoutPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    final isPreviewActive = kDebugMode && showFullLayoutPreview;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute responsive canvas dimensions adhering to aspect ratio
        final availableWidth = constraints.maxWidth;
        // Limit max bus width to 380 for optimal tablet/web readability
        final busWidth = availableWidth > 380 ? 380.0 : availableWidth;
        final busHeight = busWidth / aspectRatio;

        return Center(
          child: SizedBox(
            width: busWidth,
            height: busHeight,
            child: Stack(
              children: [
                // 1. Non-interactive Vector Bus Chassis Base
                Positioned.fill(
                  child: CustomPaint(
                    painter: BusInteriorBasePainter(locale: locale),
                    size: Size(busWidth, busHeight),
                  ),
                ),

                // 2. Interactive / Preview Seat Widgets positioned by normalized coordinates
                ...BusSeatLayoutConfig.slots28.asMap().entries.map((entry) {
                  final index = entry.key;
                  final slot = entry.value;

                  final matchedSeat = BusSeatLayoutConfig.resolveSeatForSlot(
                    slot: slot,
                    seats: seats,
                  );

                  SeatVisualState visualState =
                      BusSeatLayoutConfig.resolveVisualState(
                        seat: matchedSeat,
                        selectedSeat: selectedSeat,
                      );

                  // STRICT SAFETY RULE:
                  // Only in DEBUG builds AND when preview is enabled:
                  // Unconfigured physical slots render with preview visual state.
                  // In RELEASE / PROFILE builds: remains unconfigured (muted silhouette).
                  if (matchedSeat == null && isPreviewActive) {
                    visualState = SeatVisualState.available;
                  }

                  // Calculate pixel coordinates from normalized factors
                  final seatWidth = slot.widthFactor * busWidth;
                  final seatHeight = slot.heightFactor * busHeight;
                  final left = slot.x * busWidth;
                  final top = slot.y * busHeight;

                  final seatLabel =
                      matchedSeat?.seatNumber ??
                      (isPreviewActive ? '${index + 1}' : '');

                  return Positioned(
                    left: left,
                    top: top,
                    width: seatWidth,
                    height: seatHeight,
                    child: BusSeatVisual(
                      label: seatLabel,
                      state: visualState,
                      width: seatWidth,
                      height: seatHeight,
                      // CRITICAL RULE: Unbacked preview seats & supervisor reserved seats CANNOT book or hold!
                      onTap:
                          (matchedSeat != null &&
                              !matchedSeat.isSupervisorReserved)
                          ? () => onSeatTap(matchedSeat)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
