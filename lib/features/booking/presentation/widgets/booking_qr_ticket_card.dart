import 'package:flutter/material.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/presentation/widgets/qr_ticket_modal.dart';
import '../../domain/entities/booking_entities.dart';
import 'app_qr_ticket_widget.dart';

/// Background vector shape replicating assets/qr_scaneer.svg (445x939).
///
/// Intrinsic design geometry:
/// - width: 445
/// - height: 939
/// - aspect ratio: 445 / 939 ≈ 0.4739
/// - horizontal perforation divider: y ≈ 702.5 of 939 (≈ 74.8%)
class BookingQrTicketSvgBackground extends StatelessWidget {
  /// Reference to the authoritative asset file
  static const String assetPath = AppAssets.qrScannerTicket;

  static const double svgWidth = 445.0;
  static const double svgHeight = 939.0;
  static const double aspectRatio = svgWidth / svgHeight;
  static const double perforationRatio = 702.5 / svgHeight; // ≈ 0.7481

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double elevation;

  const BookingQrTicketSvgBackground({
    super.key,
    this.fillColor = const Color(0xFFF3F7FA), // Subtle AMOMY blue-gray tint
    this.borderColor = const Color(0xFFDCE5EC), // Soft harmonized border
    this.borderWidth = 1.0,
    this.shadowColor = const Color(0x140B192C),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BookingQrTicketPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadowColor: shadowColor,
        elevation: elevation,
      ),
    );
  }
}

class _BookingQrTicketPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double elevation;

  static Path? _cachedSvgPath;

  _BookingQrTicketPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
    required this.elevation,
  });

  static Path _getSvgPath() {
    if (_cachedSvgPath != null) return _cachedSvgPath!;
    final path = Path()..fillType = PathFillType.evenOdd;

    // Outer contour from assets/qr_scaneer.svg (445 x 939)
    path.moveTo(30.0027, 0.000019);
    path.cubicTo(13.4331, -0.00147, 0.0, 13.4304, 0.0, 30.0);
    path.lineTo(0.0, 697.997);
    path.cubicTo(0.0, 698.025, 0.0224, 698.047, 0.0500, 698.047);
    path.lineTo(17.19, 698.047);
    path.cubicTo(18.3425, 698.056, 19.4499, 698.496, 20.294, 699.281);
    path.cubicTo(21.1381, 700.066, 21.6575, 701.139, 21.75, 702.287);
    path.cubicTo(21.8236, 702.91, 21.7675, 703.541, 21.5851, 704.141);
    path.cubicTo(21.4028, 704.741, 21.0981, 705.297, 20.6904, 705.773);
    path.cubicTo(20.2826, 706.249, 19.7806, 706.636, 19.2161, 706.909);
    path.cubicTo(18.6515, 707.181, 18.0365, 707.334, 17.41, 707.357);
    path.lineTo(0.0900, 707.357);
    path.cubicTo(0.0624, 707.357, 0.03998, 707.38, 0.03998, 707.407);
    path.lineTo(0.03998, 938.407);
    path.cubicTo(0.03998, 938.435, 0.06228, 938.457, 0.08978, 938.457);
    path.lineTo(26.5548, 938.457);
    path.cubicTo(26.5774, 938.457, 26.599, 938.448, 26.615, 938.432);
    path.cubicTo(26.631, 938.416, 26.64, 938.395, 26.64, 938.372);
    path.cubicTo(26.6581, 925.318, 36.6011, 914.757, 48.81, 914.757);
    path.cubicTo(61.03, 914.757, 70.94, 925.337, 70.96, 938.407);
    path.cubicTo(70.96, 938.435, 70.9823, 938.457, 71.0098, 938.457);
    path.lineTo(83.4902, 938.457);
    path.cubicTo(83.5177, 938.457, 83.54, 938.435, 83.54, 938.407);
    path.cubicTo(83.54, 925.337, 93.54, 914.757, 105.71, 914.757);
    path.cubicTo(117.88, 914.757, 127.84, 925.337, 127.87, 938.407);
    path.cubicTo(127.87, 938.435, 127.892, 938.457, 127.92, 938.457);
    path.lineTo(140.4, 938.457);
    path.cubicTo(140.428, 938.457, 140.45, 938.435, 140.45, 938.407);
    path.cubicTo(140.45, 925.337, 150.45, 914.757, 162.62, 914.757);
    path.cubicTo(164.739, 914.766, 166.844, 915.104, 168.86, 915.757);
    path.cubicTo(178.04, 918.627, 184.75, 927.698, 184.77, 938.448);
    path.cubicTo(184.77, 938.475, 184.792, 938.497, 184.82, 938.497);
    path.lineTo(197.29, 938.497);
    path.cubicTo(197.318, 938.497, 197.34, 938.475, 197.34, 938.448);
    path.cubicTo(197.34, 925.378, 207.27, 914.797, 219.49, 914.797);
    path.cubicTo(231.71, 914.797, 241.64, 925.378, 241.66, 938.448);
    path.cubicTo(241.66, 938.475, 241.682, 938.497, 241.71, 938.497);
    path.lineTo(254.19, 938.497);
    path.cubicTo(254.218, 938.497, 254.24, 938.475, 254.24, 938.448);
    path.cubicTo(254.24, 925.378, 264.18, 914.797, 276.4, 914.797);
    path.cubicTo(288.62, 914.797, 298.54, 925.378, 298.57, 938.448);
    path.cubicTo(298.57, 938.475, 298.592, 938.497, 298.62, 938.497);
    path.lineTo(311.1, 938.497);
    path.cubicTo(311.128, 938.497, 311.15, 938.475, 311.15, 938.448);
    path.cubicTo(311.15, 925.378, 321.08, 914.797, 333.3, 914.797);
    path.cubicTo(345.52, 914.797, 355.45, 925.378, 355.47, 938.448);
    path.cubicTo(355.47, 938.475, 355.492, 938.497, 355.52, 938.497);
    path.lineTo(367.99, 938.497);
    path.cubicTo(368.018, 938.497, 368.04, 938.475, 368.04, 938.448);
    path.cubicTo(368.04, 925.378, 377.97, 914.797, 390.19, 914.797);
    path.cubicTo(402.41, 914.797, 412.32, 925.378, 412.34, 938.448);
    path.cubicTo(412.34, 938.475, 412.362, 938.497, 412.39, 938.497);
    path.lineTo(443.55, 938.497);
    path.cubicTo(443.578, 938.497, 443.6, 938.475, 443.6, 938.448);
    path.lineTo(443.6, 707.448);
    path.cubicTo(443.6, 707.42, 443.578, 707.397, 443.55, 707.397);
    path.lineTo(425.79, 707.397);
    path.cubicTo(424.62, 707.303, 423.528, 706.772, 422.732, 705.91);
    path.cubicTo(421.936, 705.047, 421.494, 703.916, 421.494, 702.742);
    path.cubicTo(421.494, 701.569, 421.936, 700.438, 422.732, 699.575);
    path.cubicTo(423.528, 698.713, 424.62, 698.181, 425.79, 698.087);
    path.lineTo(444.12, 698.087);
    path.cubicTo(444.148, 698.087, 444.17, 698.065, 444.17, 698.037);
    path.lineTo(444.17, 30.0347);
    path.cubicTo(444.17, 13.4672, 430.74, 0.0361, 414.173, 0.03465);
    path.lineTo(30.0027, 0.000019);
    path.close();

    // 5 perforation slots along y ≈ 702.5
    void addSlot(double startX, double endX) {
      path.moveTo(startX, 698.077);
      path.cubicTo(startX + 0.627, 698.101, startX + 1.242, 698.253, startX + 1.806, 698.526);
      path.cubicTo(startX + 2.371, 698.799, startX + 2.873, 699.186, startX + 3.28, 699.662);
      path.cubicTo(startX + 3.688, 700.138, startX + 3.993, 700.694, startX + 4.175, 701.294);
      path.cubicTo(startX + 4.357, 701.894, startX + 4.414, 702.525, startX + 4.34, 703.147);
      path.cubicTo(startX + 4.248, 704.296, startX + 3.728, 705.369, startX + 2.884, 706.154);
      path.cubicTo(startX + 2.04, 706.938, startX + 0.932, 707.379, startX - 0.22, 707.387);
      path.lineTo(endX, 707.387);
      path.cubicTo(endX - 1.17, 707.293, endX - 2.262, 706.762, endX - 3.058, 705.9);
      path.cubicTo(endX - 3.854, 705.037, endX - 4.296, 703.906, endX - 4.296, 702.732);
      path.cubicTo(endX - 4.296, 701.559, endX - 3.854, 700.428, endX - 3.058, 699.565);
      path.cubicTo(endX - 2.262, 698.703, endX - 1.17, 698.171, endX, 698.077);
      path.lineTo(startX, 698.077);
      path.close();
    }

    addSlot(405.88, 348.1);
    addSlot(328.19, 270.41);
    addSlot(250.27, 192.69);
    addSlot(172.58, 115.02);
    addSlot(94.88, 37.32);

    _cachedSvgPath = path;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / BookingQrTicketSvgBackground.svgWidth;
    final scaleY = size.height / BookingQrTicketSvgBackground.svgHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final path = _getSvgPath();

    if (elevation > 0) {
      canvas.drawShadow(
        path,
        shadowColor,
        elevation,
        true,
      );
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (borderWidth > 0 && borderColor.a > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth / ((scaleX + scaleY) / 2);
      canvas.drawPath(path, borderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookingQrTicketPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

/// The complete printed booking ticket widget built on qr_scaneer.svg.
class BookingQrTicketCard extends StatelessWidget {
  /// Reference to authoritative asset path
  static const String assetPath = AppAssets.qrScannerTicket;

  final PassengerBooking booking;
  final double ticketWidth;
  final double ticketHeight;
  final bool isAr;
  final String locale;
  final double feedProgress;

  const BookingQrTicketCard({
    super.key,
    required this.booking,
    required this.ticketWidth,
    required this.ticketHeight,
    required this.isAr,
    required this.locale,
    this.feedProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final mainAreaHeight =
        ticketHeight * BookingQrTicketSvgBackground.perforationRatio;
    final tearOffHeight = ticketHeight - mainAreaHeight;

    // No rectangular BoxShadow on outer container — preserves full transparency
    // through the bottom scalloped notches and perforation slots!
    return SizedBox(
      key: const ValueKey(AppAssets.qrScannerTicket),
      width: ticketWidth,
      height: ticketHeight,
      child: Stack(
        children: [
          // 1. Authoritative Vector SVG Background with subtle tinted surface & path shadow
          Positioned.fill(
            child: BookingQrTicketSvgBackground(
              fillColor: const Color(0xFFF3F7FA), // Light AMOMY blue-gray tint
              borderColor: const Color(0xFFDCE5EC), // Soft harmonious border
              borderWidth: 1.0,
              elevation: 2.5 * feedProgress,
              shadowColor: Colors.black.withValues(
                alpha: (0.10 * feedProgress).clamp(0.0, 0.12),
              ),
            ),
          ),

          // 2. Main Ticket Content Area (Upper zone, 0% to 74.8%):
          // Large prominent QR code at top (~50% of zone), followed by From/To route card with time on side
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mainAreaHeight,
            child: _MainTicketArea(
              booking: booking,
              isAr: isAr,
              locale: locale,
            ),
          ),

          // 3. Bottom Tear-Off Area (Lower zone, 74.8% to 100%):
          // 2 rows of journey meta (Date, Seat, Fare, Bus) with generous bottom padding for cutouts
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: tearOffHeight,
            child: _TearOffMetaArea(
              booking: booking,
              isAr: isAr,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upper zone (0% – 74.8%):
/// 1. Top: Prominent large QR Code occupying ~50% of upper ticket.
/// 2. Underneath: From & To Route Card matching My Trips style with departure time on the side.
class _MainTicketArea extends StatelessWidget {
  final PassengerBooking booking;
  final bool isAr;
  final String locale;

  const _MainTicketArea({
    required this.booking,
    required this.isAr,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final origin = booking.stopName ?? booking.originName(locale);
    final destination = booking.destinationName(locale);
    final originLoc = booking.locality;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        // Large QR dynamically sized to take ~45-50% of upper area (~110-135px)
        final qrSize = (availableH * 0.28).clamp(95.0, 135.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP QR CODE SECTION (Prominent, occupies top ~50% of upper ticket)
              Center(
                child: InkWell(
                  onTap: () {
                    QrTicketModal.show(
                      context,
                      departureTime: booking.departureTime,
                      originName: origin,
                      destinationName: destination,
                      seatNumber: booking.seatNumber,
                      farePoints: booking.farePoints,
                      qrToken: booking.qrToken,
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDCE5EC),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppQrTicketWidget(
                          data: booking.qrToken,
                          size: qrSize,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'امسح للصعود' : 'Scan to board',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr
                              ? 'مقعد ${booking.seatNumber}'
                              : 'Seat ${booking.seatNumber}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 2. ROUTE CARD (From & To matching My Trips style with Departure Time on side)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row: Direction info + Departure Time Badge on the side
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bus_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAr
                                  ? (booking.direction == BookingDirection.outbound
                                      ? 'رحلة الذهاب'
                                      : 'رحلة العودة')
                                  : (booking.direction == BookingDirection.outbound
                                      ? 'Outbound Trip'
                                      : 'Return Trip'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475467),
                              ),
                            ),
                          ],
                        ),
                        // DEPARTURE TIME BADGE ON THE SIDE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                booking.departureTime,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ORIGIN STOP (From)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isAr ? 'من: ' : 'From: ',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            origin,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF101828),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (originLoc != null && originLoc.isNotEmpty)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: isAr ? 0 : 27,
                          end: isAr ? 27 : 0,
                        ),
                        child: Text(
                          originLoc,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // VERTICAL CONNECTOR
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: isAr ? 0 : 9.5,
                        end: isAr ? 9.5 : 0,
                      ),
                      child: Container(
                        width: 1.5,
                        height: 7,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),

                    // DESTINATION STOP (To)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD49B00).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD49B00).withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: Color(0xFFD49B00),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isAr ? 'إلى: ' : 'To: ',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            destination,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF101828),
                              letterSpacing: -0.2,
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
            ],
          ),
        );
      },
    );
  }
}

/// Lower tear-off zone (74.8% – 100%):
/// 2 rows of journey meta (Date, Seat, Fare, Bus) with generous bottom padding
/// to keep all content well clear of the transparent scalloped cutouts!
class _TearOffMetaArea extends StatelessWidget {
  final PassengerBooking booking;
  final bool isAr;
  final String locale;

  const _TearOffMetaArea({
    required this.booking,
    required this.isAr,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      // Generous bottom padding (20px) leaves scallop cutouts completely clear & transparent
      padding: const EdgeInsets.only(
        top: 10.0,
        bottom: 20.0,
        left: 12.0,
        right: 12.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ROW 1: Date & Seat
          Row(
            children: [
              _buildMetaBox(
                icon: Icons.calendar_today_rounded,
                label: isAr ? 'التاريخ' : 'Date',
                value: _formatDate(booking.serviceDate, isAr),
              ),
              const SizedBox(width: 8),
              _buildMetaBox(
                icon: Icons.event_seat_rounded,
                label: isAr ? 'المقعد' : 'Seat',
                value: booking.seatNumber,
                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ROW 2: Fare & Bus Info
          Row(
            children: [
              _buildMetaBox(
                icon: Icons.confirmation_number_rounded,
                label: isAr ? 'الأجرة' : 'Fare',
                value: '${booking.farePoints.toInt()} ${l10n.pointsUnit}',
              ),
              const SizedBox(width: 8),
              _buildMetaBox(
                icon: Icons.directions_bus_rounded,
                label: isAr ? 'الحافلة' : 'Bus',
                value: isAr ? 'حافلة 1' : 'Bus 1',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBox({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: highlight ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: highlight ? AppColors.primary : const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool isAr) {
    const enMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${enMonths[(date.month - 1).clamp(0, 11)]}';
  }
}
