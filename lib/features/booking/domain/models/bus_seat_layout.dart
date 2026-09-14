import 'package:equatable/equatable.dart';
import '../entities/booking_entities.dart';

/// Physical section of the bus cabin.
enum SeatSection { frontSingle, left, right, rear }

/// Visual status of a physical seat slot in the interactive map.
enum SeatVisualState {
  available,
  selected,
  bookedMale,
  bookedFemale,
  held,
  unavailable,
  unconfigured,
}

/// Represents the physical geometry and location of a seat within the bus cabin.
///
/// All coordinates are normalized (0.0 -> 1.0)
/// relative to the internal bus canvas.
class BusSeatSlot extends Equatable {
  final String slotKey;
  final SeatSection section;

  /// Normalized horizontal CENTER.
  final double x;

  /// Normalized vertical CENTER.
  final double y;

  /// Normalized width relative to the whole canvas width.
  final double widthFactor;

  /// Normalized height relative to the whole canvas height.
  final double heightFactor;

  /// Rotation in radians.
  final double rotation;

  const BusSeatSlot({
    required this.slotKey,
    required this.section,
    required this.x,
    required this.y,
    this.widthFactor = 0.130,
    this.heightFactor = 0.074,
    this.rotation = 0.0,
  });

  @override
  List<Object?> get props => [
    slotKey,
    section,
    x,
    y,
    widthFactor,
    heightFactor,
    rotation,
  ];
}

/// Authoritative physical layout configuration for AMOMY's 28-seat bus.
///
/// Physical structure:
///
/// FRONT
///
/// Driver                      Front single seat
///
/// Left side                     Door / Steps
/// 6 × 2 seats
///                               Right side
///                               5 × 2 seats
///
///               aisle
///
/// Rear connected bench: 5 seats
///
/// Total:
/// 1 + 12 + 10 + 5 = 28 passenger seats.
class BusSeatLayoutConfig {
  const BusSeatLayoutConfig._();

  // ===========================================================================
  // CANVAS
  // ===========================================================================

  static const double baseCanvasWidth = 320.0;
  static const double baseCanvasHeight = 680.0;

  static const double canvasAspectRatio = baseCanvasWidth / baseCanvasHeight;

  // ===========================================================================
  // HORIZONTAL GEOMETRY
  //
  // Adjusted to:
  // - shift the whole seating mass slightly LEFT
  // - keep the center aisle visually centered between left/right groups
  // - give more balanced margin between outer wall and seats
  // - pull the front single seat inward so it sits cleaner before the door
  // ===========================================================================

  static const double leftWindowX = 0.125;
  static const double leftAisleX = 0.265;

  static const double rightAisleX = 0.605;
  static const double rightWindowX = 0.745;

  /// Front standalone passenger seat.
  ///
  /// Pulled slightly LEFT and aligned more cleanly with driver zone.
  static const double frontSingleX = 0.605;

  // ===========================================================================
  // VERTICAL GEOMETRY
  //
  // All passenger seats are pushed slightly UPWARD so the cabin fills the bus
  // shell better and the rear bench sits properly inside its dedicated area.
  // ===========================================================================

  /// Standalone front passenger seat aligned with the driver seat.
  static const double frontSingleY = 0.145;

  /// LEFT SIDE
  static const double leftRow1Y = 0.222;
  static const double leftRow2Y = 0.314;
  static const double leftRow3Y = 0.421;
  static const double leftRow4Y = 0.528;
  static const double leftRow5Y = 0.635;
  static const double leftRow6Y = 0.728;

  /// RIGHT SIDE
  static const double rightRow1Y = 0.314;
  static const double rightRow2Y = 0.421;
  static const double rightRow3Y = 0.528;
  static const double rightRow4Y = 0.635;
  static const double rightRow5Y = 0.728;

  /// Rear connected five-place bench.
  static const double rearBenchY = 0.838;

  // ===========================================================================
  // SEAT DIMENSIONS
  // ===========================================================================

  static const double standardSeatWidth = 0.128;
  static const double standardSeatHeight = 0.074;

  /// Rear seats slightly narrower/tighter so they fit as one connected bench.
  static const double rearSeatWidth = 0.134;
  static const double rearSeatHeight = 0.074;

  // ===========================================================================
  // 28 PHYSICAL PASSENGER SLOTS
  // ===========================================================================

  static const List<BusSeatSlot> slots28 = [
    // ========================================================================
    // FRONT-RIGHT STANDALONE PASSENGER SEAT
    // BEFORE the entrance door / stairs.
    // ========================================================================
    BusSeatSlot(
      slotKey: 'front_single',
      section: SeatSection.frontSingle,
      x: frontSingleX,
      y: frontSingleY,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // ========================================================================
    // LEFT SIDE
    // 6 rows × 2 seats = 12 passenger seats
    // ========================================================================

    // Left Row 1
    BusSeatSlot(
      slotKey: 'left_r1_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow1Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r1_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow1Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Left Row 2
    BusSeatSlot(
      slotKey: 'left_r2_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow2Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r2_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow2Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Left Row 3
    BusSeatSlot(
      slotKey: 'left_r3_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow3Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r3_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow3Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Left Row 4
    BusSeatSlot(
      slotKey: 'left_r4_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow4Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r4_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow4Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Left Row 5
    BusSeatSlot(
      slotKey: 'left_r5_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow5Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r5_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow5Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Left Row 6
    BusSeatSlot(
      slotKey: 'left_r6_window',
      section: SeatSection.left,
      x: leftWindowX,
      y: leftRow6Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'left_r6_aisle',
      section: SeatSection.left,
      x: leftAisleX,
      y: leftRow6Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // ========================================================================
    // RIGHT SIDE
    // 5 rows × 2 seats = 10 passenger seats
    // ========================================================================

    // Right Row 1
    BusSeatSlot(
      slotKey: 'right_r1_aisle',
      section: SeatSection.right,
      x: rightAisleX,
      y: rightRow1Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'right_r1_window',
      section: SeatSection.right,
      x: rightWindowX,
      y: rightRow1Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Right Row 2
    BusSeatSlot(
      slotKey: 'right_r2_aisle',
      section: SeatSection.right,
      x: rightAisleX,
      y: rightRow2Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'right_r2_window',
      section: SeatSection.right,
      x: rightWindowX,
      y: rightRow2Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Right Row 3
    BusSeatSlot(
      slotKey: 'right_r3_aisle',
      section: SeatSection.right,
      x: rightAisleX,
      y: rightRow3Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'right_r3_window',
      section: SeatSection.right,
      x: rightWindowX,
      y: rightRow3Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Right Row 4
    BusSeatSlot(
      slotKey: 'right_r4_aisle',
      section: SeatSection.right,
      x: rightAisleX,
      y: rightRow4Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'right_r4_window',
      section: SeatSection.right,
      x: rightWindowX,
      y: rightRow4Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // Right Row 5
    BusSeatSlot(
      slotKey: 'right_r5_aisle',
      section: SeatSection.right,
      x: rightAisleX,
      y: rightRow5Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'right_r5_window',
      section: SeatSection.right,
      x: rightWindowX,
      y: rightRow5Y,
      widthFactor: standardSeatWidth,
      heightFactor: standardSeatHeight,
    ),

    // ========================================================================
    // REAR CONNECTED BENCH
    //
    // Tightened and centered so the five seats sit inside the rear platform
    // and visually read as one shared rear bench split into five positions.
    // ========================================================================
    BusSeatSlot(
      slotKey: 'rear_1',
      section: SeatSection.rear,
      x: 0.125,
      y: rearBenchY,
      widthFactor: rearSeatWidth,
      heightFactor: rearSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'rear_2',
      section: SeatSection.rear,
      x: 0.265,
      y: rearBenchY,
      widthFactor: rearSeatWidth,
      heightFactor: rearSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'rear_3',
      section: SeatSection.rear,
      x: 0.440,
      y: rearBenchY,
      widthFactor: rearSeatWidth,
      heightFactor: rearSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'rear_4',
      section: SeatSection.rear,
      x: 0.605,
      y: rearBenchY,
      widthFactor: rearSeatWidth,
      heightFactor: rearSeatHeight,
    ),
    BusSeatSlot(
      slotKey: 'rear_5',
      section: SeatSection.rear,
      x: 0.745,
      y: rearBenchY,
      widthFactor: rearSeatWidth,
      heightFactor: rearSeatHeight,
    ),
  ];

  // ===========================================================================
  // AUTHORITATIVE 28-SEAT PHYSICAL NUMBER MAPPING
  //
  // Physical passenger seat numbers '1' through '28' mapped directly to slots.
  // ===========================================================================

  static const Map<String, String> seatNumberToSlotKey28 = {
    '1': 'front_single',

    // LEFT SIDE: 6 rows × 2 = 12 seats
    '2': 'left_r1_window',
    '3': 'left_r1_aisle',

    '4': 'left_r2_window',
    '5': 'left_r2_aisle',

    '6': 'left_r3_window',
    '7': 'left_r3_aisle',

    '8': 'left_r4_window',
    '9': 'left_r4_aisle',

    '10': 'left_r5_window',
    '11': 'left_r5_aisle',

    '12': 'left_r6_window',
    '13': 'left_r6_aisle',

    // RIGHT SIDE: 5 rows × 2 = 10 seats
    '14': 'right_r1_aisle',
    '15': 'right_r1_window',

    '16': 'right_r2_aisle',
    '17': 'right_r2_window',

    '18': 'right_r3_aisle',
    '19': 'right_r3_window',

    '20': 'right_r4_aisle',
    '21': 'right_r4_window',

    '22': 'right_r5_aisle',
    '23': 'right_r5_window',

    // REAR CONNECTED BENCH: 5 seats
    '24': 'rear_1',
    '25': 'rear_2',
    '26': 'rear_3',
    '27': 'rear_4',
    '28': 'rear_5',
  };

  // ===========================================================================
  // LEGACY 14-SEAT BACKEND MAPPING (BACKWARDS COMPATIBILITY)
  // ===========================================================================

  static const Map<String, String> default14SeatSlotMapping = {
    '1A': 'front_single',

    '1B': 'left_r1_window',
    '1C': 'left_r1_aisle',

    '2A': 'left_r2_window',
    '2B': 'left_r2_aisle',

    '2C': 'right_r1_aisle',
    '3B': 'right_r1_window',

    '3A': 'left_r3_window',
    '3C': 'right_r2_aisle',

    '4A': 'rear_1',
    '4B': 'rear_2',
    '4C': 'rear_3',
    '4D': 'rear_4',
    '4E': 'rear_5',
  };

  /// Resolves the backend TripSeat for a physical slot.
  static TripSeat? resolveSeatForSlot({
    required BusSeatSlot slot,
    required List<TripSeat> seats,
  }) {
    if (seats.isEmpty) return null;

    // -----------------------------------------------------------------------
    // 1. Authoritative 28-seat physical number mapping ('1'..'28').
    // Primary path for the migrated 28-seat fleet.
    // -----------------------------------------------------------------------
    for (final entry in seatNumberToSlotKey28.entries) {
      if (entry.value != slot.slotKey) continue;

      for (final seat in seats) {
        if (seat.seatNumber.trim() == entry.key) {
          return seat;
        }
      }
    }

    // -----------------------------------------------------------------------
    // 2. Direct physical slot-key match (if backend seatNumber equals slotKey).
    // -----------------------------------------------------------------------
    for (final seat in seats) {
      if (seat.seatNumber.toLowerCase() == slot.slotKey.toLowerCase()) {
        return seat;
      }
    }

    // -----------------------------------------------------------------------
    // 3. Legacy 14-seat mapping ('1A'..'4E') for backwards compatibility.
    // -----------------------------------------------------------------------
    for (final entry in default14SeatSlotMapping.entries) {
      if (entry.value != slot.slotKey) continue;

      for (final seat in seats) {
        if (seat.seatNumber.toUpperCase() == entry.key.toUpperCase()) {
          return seat;
        }
      }
    }

    // -----------------------------------------------------------------------
    // 4. Fallback index matching if backend contains >= 28 seats.
    // -----------------------------------------------------------------------
    if (seats.length >= 28) {
      final slotIndex = slots28.indexOf(slot);

      if (slotIndex >= 0 && slotIndex < seats.length) {
        return seats[slotIndex];
      }
    }

    return null;
  }

  /// Resolves visual rendering state from the authoritative backend seat.
  ///
  /// Contract:
  /// A) Selected by current user -> [SeatVisualState.selected]
  /// B) is_mine == true AND status == held -> [SeatVisualState.selected]
  /// C) status == booked AND passenger_gender == 'male' -> [SeatVisualState.bookedMale]
  /// D) status == booked AND passenger_gender == 'female' -> [SeatVisualState.bookedFemale]
  /// E) status == booked AND passenger_gender == null -> [SeatVisualState.unavailable]
  /// F) status == held AND is_mine == false -> [SeatVisualState.held]
  /// G) status == available -> [SeatVisualState.available]
  /// Everything else -> [SeatVisualState.unavailable]
  static SeatVisualState resolveVisualState({
    BusSeatSlot? slot,
    required TripSeat? seat,
    required TripSeat? selectedSeat,
  }) {
    if (seat == null) {
      return SeatVisualState.unconfigured;
    }

    // A) Selected by current user
    if (selectedSeat != null && selectedSeat.seatId == seat.seatId) {
      return SeatVisualState.selected;
    }

    // B) is_mine == true AND status == held (user's active hold)
    if (seat.isMine && seat.status == SeatAvailabilityStatus.held) {
      return SeatVisualState.selected;
    }

    // C, D, E) Booked status
    if (seat.status == SeatAvailabilityStatus.booked) {
      final gender = seat.passengerGender?.trim().toLowerCase();
      if (gender == 'male') {
        return SeatVisualState.bookedMale;
      }
      if (gender == 'female') {
        return SeatVisualState.bookedFemale;
      }
      return SeatVisualState.unavailable;
    }

    // F) status == held AND is_mine == false
    if (seat.status == SeatAvailabilityStatus.held && !seat.isMine) {
      return SeatVisualState.held;
    }

    // G) status == available
    if (seat.status == SeatAvailabilityStatus.available) {
      return SeatVisualState.available;
    }

    return SeatVisualState.unavailable;
  }
}
