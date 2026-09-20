import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the architectural interior chassis of the bus.
///
/// Top-view semi-realistic coach interior:
/// - Integrated front body shell with flush headlamp units and body-anchored aerodynamic mirrors.
/// - Dark charcoal / graphite cabin floor with seamless textured central aisle and anti-slip tread.
/// - Left-side driver cockpit (y: ~0.08 to 0.22) with curved dashboard, steering wheel assembly,
///   contoured driver seat, and safety partition rail (no text).
/// - Right-side boarding threshold (y: ~0.21 to 0.30) opposite the door frame with 3 shallow steps,
///   anti-slip strips, and slim chrome handrail.
/// - Subtle seating zone floor depth and cohesive rear bench foundation.
/// - NO passenger seats (passenger seats rendered dynamically via [BusSeatVisual]).
class BusInteriorBasePainter extends CustomPainter {
  final String locale;

  const BusInteriorBasePainter({required this.locale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scaling factors relative to canonical coordinates (320 x 680)
    final sx = w / 320.0;
    final sy = h / 680.0;

    // -------------------------------------------------------------------------
    // 1. AERODYNAMIC SIDE MIRRORS (Anchored cleanly to front A-pillars)
    // -------------------------------------------------------------------------
    final mirrorFill = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final mirrorGlass = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final mirrorBorder = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * sx;

    // Left Mirror: Robust bracket attaching directly into body pillar at y: 68-76
    final leftBracket = Path()
      ..moveTo(26 * sx, 66 * sy)
      ..lineTo(10 * sx, 74 * sy)
      ..lineTo(10 * sx, 82 * sy)
      ..lineTo(26 * sx, 74 * sy)
      ..close();
    canvas.drawPath(leftBracket, mirrorFill);

    final leftMirrorHousing = Path()
      ..moveTo(12 * sx, 68 * sy)
      ..quadraticBezierTo(2 * sx, 74 * sy, 4 * sx, 92 * sy)
      ..quadraticBezierTo(16 * sx, 89 * sy, 17 * sx, 78 * sy)
      ..close();
    canvas.drawPath(leftMirrorHousing, mirrorFill);
    canvas.drawPath(leftMirrorHousing, mirrorBorder);

    final leftMirrorGlassPath = Path()
      ..moveTo(10 * sx, 72 * sy)
      ..quadraticBezierTo(4 * sx, 77 * sy, 6 * sx, 88 * sy)
      ..lineTo(12 * sx, 83 * sy)
      ..close();
    canvas.drawPath(leftMirrorGlassPath, mirrorGlass);

    // Right Mirror: Symmetric mounting bracket
    final rightBracket = Path()
      ..moveTo(294 * sx, 66 * sy)
      ..lineTo(310 * sx, 74 * sy)
      ..lineTo(310 * sx, 82 * sy)
      ..lineTo(294 * sx, 74 * sy)
      ..close();
    canvas.drawPath(rightBracket, mirrorFill);

    final rightMirrorHousing = Path()
      ..moveTo(308 * sx, 68 * sy)
      ..quadraticBezierTo(318 * sx, 74 * sy, 316 * sx, 92 * sy)
      ..quadraticBezierTo(304 * sx, 89 * sy, 303 * sx, 78 * sy)
      ..close();
    canvas.drawPath(rightMirrorHousing, mirrorFill);
    canvas.drawPath(rightMirrorHousing, mirrorBorder);

    final rightMirrorGlassPath = Path()
      ..moveTo(310 * sx, 72 * sy)
      ..quadraticBezierTo(316 * sx, 77 * sy, 314 * sx, 88 * sy)
      ..lineTo(308 * sx, 83 * sy)
      ..close();
    canvas.drawPath(rightMirrorGlassPath, mirrorGlass);

    // -------------------------------------------------------------------------
    // 2. BUS CHASSIS DROP SHADOW & EXTERIOR BODY SHELL
    // -------------------------------------------------------------------------
    final outerShellPath = Path()
      ..moveTo(32 * sx, 56 * sy)
      ..cubicTo(32 * sx, 20 * sy, 288 * sx, 20 * sy, 288 * sx, 56 * sy)
      ..lineTo(298 * sx, 130 * sy)
      ..lineTo(298 * sx, 630 * sy)
      ..cubicTo(298 * sx, 672 * sy, 22 * sx, 672 * sy, 22 * sx, 630 * sy)
      ..lineTo(22 * sx, 130 * sy)
      ..close();

    // Ambient ground shadow
    final chassisShadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(outerShellPath, chassisShadow);

    // -------------------------------------------------------------------------
    // 2. BUS CHASSIS DROP SHADOW & EXTERIOR BODY SHELL (Cool Blue-Grey Automotive Metallic)
    // -------------------------------------------------------------------------
    // Multi-layer ambient chassis drop shadow
    final chassisOuterShadow = Paint()
      ..color = const Color(0x3D020617)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(outerShellPath, chassisOuterShadow);

    final chassisContactShadow = Paint()
      ..color = const Color(0x520B1120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(outerShellPath, chassisContactShadow);

    // Exterior automotive metallic coach body shell in light cool blue-grey
    final chassisBodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF88A0B8), // Outer left bevel shadow
          Color(0xFFB4C7D8), // Left curved shoulder
          Color(0xFFD9E5F0), // Top metallic specular highlight
          Color(0xFFC0D1E1), // Right subtle tone
          Color(0xFF88A0B8), // Outer right bevel shadow
        ],
        stops: [0.0, 0.18, 0.50, 0.82, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final chassisOutline = Paint()
      ..color = const Color(0xFF5A738E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * sx;

    canvas.drawPath(outerShellPath, chassisBodyPaint);
    canvas.drawPath(outerShellPath, chassisOutline);

    // Subtle inner specular shoulder highlight on body shell
    final shoulderHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * sx;
    final shoulderPath = Path()
      ..moveTo(34 * sx, 56 * sy)
      ..cubicTo(34 * sx, 23 * sy, 286 * sx, 23 * sy, 286 * sx, 56 * sy)
      ..lineTo(295 * sx, 130 * sy)
      ..lineTo(295 * sx, 626 * sy)
      ..cubicTo(295 * sx, 666 * sy, 25 * sx, 666 * sy, 25 * sx, 626 * sy)
      ..lineTo(25 * sx, 130 * sy)
      ..close();
    canvas.drawPath(shoulderPath, shoulderHighlight);

    // Exterior Side Protective Rub Strips (Aerodynamic coach side moldings)
    final rubStripPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * sx
      ..strokeCap = StrokeCap.round;
    // Left rub strip
    canvas.drawLine(
      Offset(21.2 * sx, 132 * sy),
      Offset(21.2 * sx, 624 * sy),
      rubStripPaint,
    );
    // Right rub strip
    canvas.drawLine(
      Offset(298.8 * sx, 132 * sy),
      Offset(298.8 * sx, 624 * sy),
      rubStripPaint,
    );

    // Architectural Panel Shut Lines (Front fender & rear quarter seams)
    final panelSeamPaint = Paint()
      ..color = const Color(0xFF5A738E).withValues(alpha: 0.8)
      ..strokeWidth = 1.0 * sx;
    // Front left & right panel seams
    canvas.drawLine(
      Offset(22 * sx, 128 * sy),
      Offset(31 * sx, 128 * sy),
      panelSeamPaint,
    );
    canvas.drawLine(
      Offset(289 * sx, 128 * sy),
      Offset(298 * sx, 128 * sy),
      panelSeamPaint,
    );
    // Rear left & right panel seams
    canvas.drawLine(
      Offset(22 * sx, 614 * sy),
      Offset(30 * sx, 614 * sy),
      panelSeamPaint,
    );
    canvas.drawLine(
      Offset(290 * sx, 614 * sy),
      Offset(298 * sx, 614 * sy),
      panelSeamPaint,
    );

    // Integrated front headlamp clusters (flush inside front bumper curvature)
    _drawIntegratedHeadlamps(canvas, sx, sy);

    // Front Bumper Signature Electric Blue Accent Line
    final frontBumperPath = Path()
      ..moveTo(65 * sx, 28 * sy)
      ..quadraticBezierTo(160 * sx, 19 * sy, 255 * sx, 28 * sy);
    final frontBumperPaint = Paint()
      ..color = const Color(0xFF01589F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(frontBumperPath, frontBumperPaint);

    // -------------------------------------------------------------------------
    // 3. DARK INTERIOR CABIN FLOOR (Graphite / Charcoal Coach Floor)
    // -------------------------------------------------------------------------
    final cabinFloorPath = Path()
      ..moveTo(38 * sx, 60 * sy)
      ..cubicTo(38 * sx, 30 * sy, 282 * sx, 30 * sy, 282 * sx, 60 * sy)
      ..lineTo(290 * sx, 130 * sy)
      ..lineTo(290 * sx, 626 * sy)
      ..cubicTo(290 * sx, 662 * sy, 30 * sx, 662 * sy, 30 * sx, 626 * sy)
      ..lineTo(30 * sx, 130 * sy)
      ..close();

    // Dark charcoal cabin floor with subtle ambient shading
    final cabinFloorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E293B), // Front cabin threshold
          Color(0xFF0F172A), // Deep graphite cabin floor
          Color(0xFF0B1120), // Rear cabin deep shadow
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(cabinFloorPath, cabinFloorPaint);

    // Ambient inner wall drop shadow (creates realistic recessed cabin depth)
    final cabinInnerShadow = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * sx
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawPath(cabinFloorPath, cabinInnerShadow);

    // Inner side-wall thickness trim
    final innerWallTrim = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * sx;
    canvas.drawPath(cabinFloorPath, innerWallTrim);

    // Side Window Pillar Cues
    final pillarPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0 * sx;
    final pillarPositionsY = [135, 210, 285, 360, 435, 510, 585];
    for (final py in pillarPositionsY) {
      canvas.drawLine(
        Offset(25 * sx, py * sy),
        Offset(32 * sx, py * sy),
        pillarPaint,
      );
      canvas.drawLine(
        Offset(288 * sx, py * sy),
        Offset(295 * sx, py * sy),
        pillarPaint,
      );
    }

    // -------------------------------------------------------------------------
    // 4. SEATING PLATFORM SUBTLE FLOOR DEPTH & REAR BENCH FOUNDATION
    // -------------------------------------------------------------------------
    // Left seating column subtle platform shading (under rows 1-6)
    final leftPlatform = RRect.fromRectAndRadius(
      Rect.fromLTWH(34 * sx, 160 * sy, 90 * sx, 365 * sy),
      Radius.circular(6 * sx),
    );
    canvas.drawRRect(
      leftPlatform,
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    // Right seating column subtle platform shading (under rows 1-5)
    final rightPlatform = RRect.fromRectAndRadius(
      Rect.fromLTWH(196 * sx, 208 * sy, 90 * sx, 317 * sy),
      Radius.circular(6 * sx),
    );
    canvas.drawRRect(
      rightPlatform,
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    // Rear 5-seat cohesive bench platform contour (y: ~0.84 to 0.91)
    final rearBenchPlatform = RRect.fromRectAndRadius(
      Rect.fromLTWH(36 * sx, 566 * sy, 248 * sx, 56 * sy),
      Radius.circular(10 * sx),
    );
    canvas.drawRRect(
      rearBenchPlatform,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawRRect(
      rearBenchPlatform,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * sx,
    );

    // -------------------------------------------------------------------------
    // 5. CENTER AISLE FLOORING (Integrated rubber runner, not a floating card)
    // -------------------------------------------------------------------------
    final aisleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(126 * sx, 148 * sy, 68 * sx, 415 * sy),
      Radius.circular(4 * sx),
    );

    // Aisle floor subtly distinct from cabin base
    final aislePaint = Paint()..color = const Color(0xFF192231);
    canvas.drawRRect(aisleRect, aislePaint);

    // Soft border defining the aisle edge without stark high-contrast lines
    final aisleBorder = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * sx;
    canvas.drawRRect(aisleRect, aisleBorder);

    // Low-contrast rubber anti-slip tread grooves across aisle
    final treadPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.22)
      ..strokeWidth = 1.0 * sx;
    for (double y = 160; y < 555; y += 18) {
      canvas.drawLine(
        Offset(136 * sx, y * sy),
        Offset(184 * sx, y * sy),
        treadPaint,
      );
    }

    // -------------------------------------------------------------------------
    // 6. FRONT WINDSHIELD GLASS & CURVED DASHBOARD
    // -------------------------------------------------------------------------
    // Windshield contour
    final windshieldPath = Path()
      ..moveTo(46 * sx, 60 * sy)
      ..cubicTo(68 * sx, 38 * sy, 252 * sx, 38 * sy, 274 * sx, 60 * sy)
      ..lineTo(270 * sx, 82 * sy)
      ..cubicTo(235 * sx, 70 * sy, 85 * sx, 70 * sy, 50 * sx, 82 * sy)
      ..close();

    // Natural glass reflection tint (subdued, not saturated cyan banner)
    final windshieldGlass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x3560A5FA), Color(0x1838BDF8), Color(0x080F172A)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, 90 * sy));
    final windshieldOutline = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * sx;

    canvas.drawPath(windshieldPath, windshieldGlass);
    canvas.drawPath(windshieldPath, windshieldOutline);

    // Subtle curved glass glare line
    final glarePath = Path()
      ..moveTo(70 * sx, 50 * sy)
      ..quadraticBezierTo(160 * sx, 42 * sy, 250 * sx, 50 * sy);
    canvas.drawPath(
      glarePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * sx,
    );

    // Curved Dashboard Console
    final dashPath = Path()
      ..moveTo(48 * sx, 82 * sy)
      ..cubicTo(85 * sx, 70 * sy, 235 * sx, 70 * sy, 272 * sx, 82 * sy)
      ..lineTo(272 * sx, 95 * sy)
      ..lineTo(48 * sx, 95 * sy)
      ..close();

    final dashPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E384D), Color(0xFF1A2234)],
      ).createShader(Rect.fromLTWH(0, 70 * sy, w, 25 * sy));
    canvas.drawPath(dashPath, dashPaint);

    // Instrument gauge backlight strip (subtle driver cluster)
    final clusterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(56 * sx, 84 * sy, 34 * sx, 5 * sy),
      Radius.circular(2.5 * sx),
    );
    canvas.drawRRect(
      clusterRect,
      Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.6),
    );

    // -------------------------------------------------------------------------
    // 7. DRIVER COCKPIT (FRONT-LEFT: strictly y ~0.08 to 0.22)
    // -------------------------------------------------------------------------
    // Driver Seat Cushion (Visually distinct from passenger seats, non-interactive)
    final driverBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(50 * sx, 104 * sy, 40 * sx, 38 * sy),
      Radius.circular(7 * sx),
    );
    canvas.drawRRect(driverBase, Paint()..color = const Color(0xFF283347));
    canvas.drawRRect(
      driverBase,
      Paint()
        ..color = const Color(0xFF3B4861)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * sx,
    );

    // Driver Seat Headrest
    final driverHeadrest = RRect.fromRectAndRadius(
      Rect.fromLTWH(56 * sx, 98 * sy, 28 * sx, 8 * sy),
      Radius.circular(3.5 * sx),
    );
    canvas.drawRRect(driverHeadrest, Paint()..color = const Color(0xFF3B4861));

    // Steering Wheel Assembly (Offset at driver cockpit center)
    final steerCenter = Offset(70 * sx, 101 * sy);
    final steerRadius = 10.5 * sx;
    final steerRim = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * sx;
    canvas.drawCircle(steerCenter, steerRadius, steerRim);

    // Steering Center Boss
    canvas.drawCircle(
      steerCenter,
      3.5 * sx,
      Paint()..color = const Color(0xFF64748B),
    );

    // 3 Steering Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.6 * sx;
    canvas.drawLine(steerCenter, Offset(60 * sx, 106 * sy), spokePaint);
    canvas.drawLine(steerCenter, Offset(80 * sx, 106 * sy), spokePaint);
    canvas.drawLine(steerCenter, Offset(70 * sx, 90.5 * sy), spokePaint);

    // Driver Partition Safety Rail (Separates driver from passenger cabin, ends at y: 148 * sy)
    final driverPartition = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.6 * sx;
    _drawDashedLine(
      canvas,
      Offset(40 * sx, 146 * sy),
      Offset(108 * sx, 146 * sy),
      driverPartition,
      dashWidth: 4 * sx,
      dashSpace: 3 * sx,
    );

    // (Note: No "Driver" text is rendered — visual cockpit cues make role obvious)

    // -------------------------------------------------------------------------
    // 8. PASSENGER BOARDING ENTRANCE & STAIRWELL (FRONT-RIGHT: y ~0.21 to 0.30)
    // -------------------------------------------------------------------------
    // Visible door cutout frame in the bus side wall
    final doorCutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(288 * sx, 148 * sy, 6 * sx, 48 * sy),
      Radius.circular(2.5 * sx),
    );
    canvas.drawRRect(doorCutout, Paint()..color = const Color(0xFF01589F));

    // Stairwell Recessed Cavity directly opposite the door opening
    final stairCavity = RRect.fromRectAndRadius(
      Rect.fromLTWH(228 * sx, 148 * sy, 58 * sx, 48 * sy),
      Radius.circular(5 * sx),
    );
    canvas.drawRRect(stairCavity, Paint()..color = const Color(0xFF0B1120));
    canvas.drawRRect(
      stairCavity,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * sx,
    );

    // 3 Shallow Realistic Boarding Steps with Subtle Amber/Yellow Safety Edge Strips
    for (int i = 0; i < 3; i++) {
      final stepTop = (152 + i * 14) * sy;
      final stepWidth = (50 - i * 2) * sx;
      final stepLeft = 232 * sx;

      // Dark rubber tread plate
      final stepRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(stepLeft, stepTop, stepWidth, 11 * sy),
        Radius.circular(2 * sx),
      );
      canvas.drawRRect(stepRRect, Paint()..color = const Color(0xFF1E293B));

      // Subtle yellow safety warning strip on the edge
      final edgeRect = Rect.fromLTWH(
        stepLeft,
        stepTop + 9 * sy,
        stepWidth,
        2 * sy,
      );
      canvas.drawRect(
        edgeRect,
        Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.8),
      );

      // Anti-slip grooved texture
      final groovePaint = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 0.8 * sx;
      canvas.drawLine(
        Offset(stepLeft + 6 * sx, stepTop + 5 * sy),
        Offset(stepLeft + stepWidth - 6 * sx, stepTop + 5 * sy),
        groovePaint,
      );
    }

    // Slim Chrome Handrail Post at stair entrance
    final handrailPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.8 * sx;
    canvas.drawCircle(
      Offset(226 * sx, 153 * sy),
      2.4 * sx,
      Paint()..color = const Color(0xFFE2E8F0),
    );
    canvas.drawCircle(
      Offset(226 * sx, 191 * sy),
      2.4 * sx,
      Paint()..color = const Color(0xFFE2E8F0),
    );
    canvas.drawLine(
      Offset(226 * sx, 153 * sy),
      Offset(226 * sx, 191 * sy),
      handrailPaint,
    );

    // (Note: Removed large floating "DOOR" badge — physical geometry clearly identifies entrance)

    // -------------------------------------------------------------------------
    // 9. REAR BULKHEAD & ENGINE WALL
    // -------------------------------------------------------------------------
    final rearWallPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * sx
      ..strokeCap = StrokeCap.round;
    final rearWallPath = Path()
      ..moveTo(40 * sx, 626 * sy)
      ..quadraticBezierTo(160 * sx, 642 * sy, 280 * sx, 626 * sy);
    canvas.drawPath(rearWallPath, rearWallPaint);

    // Engine vent slats
    final ventPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.4 * sx;
    for (int i = 0; i < 5; i++) {
      final vy = (634 + i * 4) * sy;
      canvas.drawLine(Offset(120 * sx, vy), Offset(200 * sx, vy), ventPaint);
    }

    // Rear Impact Bumper
    final rearBumper = RRect.fromRectAndRadius(
      Rect.fromLTWH(70 * sx, 658 * sy, 180 * sx, 6 * sy),
      Radius.circular(3 * sx),
    );
    canvas.drawRRect(rearBumper, Paint()..color = const Color(0xFF475569));
  }

  /// Draws realistic LED headlamp clusters integrated directly into the front body shell corners
  void _drawIntegratedHeadlamps(Canvas canvas, double sx, double sy) {
    final housingPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final bezelPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * sx;

    // Left Headlamp Unit
    final leftLampRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(42 * sx, 34 * sy, 22 * sx, 9 * sy),
      Radius.circular(4.5 * sx),
    );
    canvas.drawRRect(leftLampRect, housingPaint);
    canvas.drawRRect(leftLampRect, bezelPaint);

    // Dual LED Projector Lenses (Warm crisp white light)
    final ledLensPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(48 * sx, 38.5 * sy), 2.6 * sx, ledLensPaint);
    canvas.drawCircle(Offset(57 * sx, 38.5 * sy), 2.6 * sx, ledLensPaint);

    // Right Headlamp Unit
    final rightLampRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(256 * sx, 34 * sy, 22 * sx, 9 * sy),
      Radius.circular(4.5 * sx),
    );
    canvas.drawRRect(rightLampRect, housingPaint);
    canvas.drawRRect(rightLampRect, bezelPaint);

    // Dual LED Projector Lenses
    canvas.drawCircle(Offset(263 * sx, 38.5 * sy), 2.6 * sx, ledLensPaint);
    canvas.drawCircle(Offset(272 * sx, 38.5 * sy), 2.6 * sx, ledLensPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0) return;
    final unitX = dx / dist;
    final unitY = dy / dist;

    double current = 0;
    while (current < dist) {
      final startX = p1.dx + unitX * current;
      final startY = p1.dy + unitY * current;
      final next = math.min(current + dashWidth, dist);
      final endX = p1.dx + unitX * next;
      final endY = p1.dy + unitY * next;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant BusInteriorBasePainter oldDelegate) {
    return oldDelegate.locale != locale;
  }
}
