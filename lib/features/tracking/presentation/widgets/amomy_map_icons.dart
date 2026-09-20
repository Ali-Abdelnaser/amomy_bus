import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Visual status states for circular bus marker.
enum BusMarkerVisualState { live, atStop, reconnecting, offline, qa }

/// Visual status states for stop pins.
enum StopPinVisualState {
  normal,
  passed,
  current,
  next,
  selected,
  selectedLast,
  selectedNext,
}

/// Bitmap descriptor generator and cache for transport stop pins and bus markers.
class AmomyMapIcons {
  static final Map<String, BitmapDescriptor> _cache = {};

  // Anchor points aligning marker geometry exactly to GPS coordinates
  static const Offset busMarkerAnchor = Offset(0.5, 0.5);
  static const Offset normalPinAnchor = Offset(0.5, 0.8857);
  static const Offset selectedPinAnchor = Offset(0.5, 0.8875);
  static const Offset stopPinAnchor = normalPinAnchor;

  static Offset getStopPinAnchor(StopPinVisualState state) {
    return (state == StopPinVisualState.selected ||
            state == StopPinVisualState.selectedLast ||
            state == StopPinVisualState.selectedNext)
        ? selectedPinAnchor
        : normalPinAnchor;
  }

  /// Preload and cache all marker descriptors upfront.
  static Future<void> preloadAllIcons() async {
    await Future.wait([
      for (final state in BusMarkerVisualState.values)
        getBusMarkerIconForState(state),
      for (final state in StopPinVisualState.values)
        getStopPinIconForState(state),
    ]);
  }

  /// Synchronous retrieval for preloaded bus icon.
  static BitmapDescriptor? getCachedBusIcon(BusMarkerVisualState state) {
    return _cache['bus_${state.name}'];
  }

  /// Synchronous retrieval for preloaded stop pin icon.
  static BitmapDescriptor? getCachedStopIcon(StopPinVisualState state) {
    return _cache['pin_${state.name}'];
  }

  /// Compact Circular Bus Marker Bitmap.
  /// Visual footprint: 36x36 logical px.
  /// Rendered at 3x retina resolution (108x108 px) with explicit dimensions.
  static Future<BitmapDescriptor> getBusMarkerIconForState(
    BusMarkerVisualState state,
  ) async {
    final key = 'bus_${state.name}';
    if (_cache.containsKey(key)) return _cache[key]!;

    const double logicalSize = 36.0;
    const double scale = 3.0;
    final int physicalSize = (logicalSize * scale).toInt();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    canvas.scale(scale);

    final Color surfaceColor;
    final Color borderColor;

    switch (state) {
      case BusMarkerVisualState.live:
        surfaceColor = AppColors.primary;
        borderColor = Colors.white;
      case BusMarkerVisualState.atStop:
        surfaceColor = AppColors.success;
        borderColor = Colors.white;
      case BusMarkerVisualState.reconnecting:
        surfaceColor = const Color(0xFF475569);
        borderColor = const Color(0xFFF59E0B);
      case BusMarkerVisualState.offline:
        surfaceColor = const Color(0xFF64748B);
        borderColor = const Color(0xFF94A3B8);
      case BusMarkerVisualState.qa:
        surfaceColor = const Color(0xFF4F46E5);
        borderColor = Colors.white;
    }

    const center = Offset(logicalSize / 2, logicalSize / 2);
    const radius =
        15.0; // 30px visual diameter + 1.5px subtle border = ~33px footprint

    // 1. Subtle, compact drop shadow (no oversized shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(center.translate(0, 1.2), radius, shadowPaint);

    // 2. Main circular surface
    final circlePaint = Paint()..color = surfaceColor;
    canvas.drawCircle(center, radius, circlePaint);

    // 3. Crisp subtle border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Centered Material Bus Glyph (proportional & crisp)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
      style: TextStyle(
        fontSize: 17.5,
        fontFamily: Icons.directions_bus_rounded.fontFamily,
        package: Icons.directions_bus_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (logicalSize - textPainter.width) / 2,
        (logicalSize - textPainter.height) / 2 - 0.5,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(physicalSize, physicalSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
      imagePixelRatio: scale,
    );

    _cache[key] = descriptor;
    return descriptor;
  }

  /// Convenience wrapper supporting boolean flags with backwards compatibility.
  static Future<BitmapDescriptor> getBusMarkerIcon({
    bool isStale = false,
    bool isQa = false,
    bool isAtStop = false,
    bool isOffline = false,
    bool isReconnecting = false,
  }) async {
    final BusMarkerVisualState state;
    if (isQa) {
      state = BusMarkerVisualState.qa;
    } else if (isOffline) {
      state = BusMarkerVisualState.offline;
    } else if (isStale || isReconnecting) {
      state = BusMarkerVisualState.reconnecting;
    } else if (isAtStop) {
      state = BusMarkerVisualState.atStop;
    } else {
      state = BusMarkerVisualState.live;
    }
    return getBusMarkerIconForState(state);
  }

  /// Redesigned Polished Stop Pin.
  /// Normal: 28x35 logical px canvas (pin ~24x31 logical px).
  /// Selected: 32x40 logical px canvas (pin ~28x35.5 logical px).
  /// Rendered at 3x retina with explicit dimensions and generous padding.
  ///
  /// Visual Hierarchy:
  /// - LAST (current): #FFC928 yellow (accent)
  /// - NEXT: #01589F blue (primary)
  /// - FUTURE (normal): white fill + subtle #94A3B8 gray border
  /// - PASSED: muted silver/gray #CBD5E1 (secondary)
  /// - SELECTED variants: preserve color identity with larger emphasis
  static Future<BitmapDescriptor> getStopPinIconForState(
    StopPinVisualState state,
  ) async {
    final key = 'pin_${state.name}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final isSelected =
        state == StopPinVisualState.selected ||
        state == StopPinVisualState.selectedLast ||
        state == StopPinVisualState.selectedNext;
    final double logicalWidth = isSelected ? 32.0 : 28.0;
    final double logicalHeight = isSelected ? 40.0 : 35.0;
    const double scale = 3.0;

    final double cx = logicalWidth / 2;
    final double cy = isSelected ? 14.0 : 12.5;
    final double headRadius = isSelected ? 11.0 : 9.5;
    final double tipY = isSelected ? 35.5 : 31.0;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    canvas.scale(scale);

    final Color bodyColor;
    final Color outlineColor;
    final Color innerDotColor;
    final double innerDotRadius;

    switch (state) {
      case StopPinVisualState.normal:
        // FUTURE STOP: white fill + subtle gray border
        bodyColor = Colors.white;
        outlineColor = const Color(0xFF94A3B8);
        innerDotColor = const Color(0xFF1E3A8A); // dark/blue center detail
        innerDotRadius = 2.6;
      case StopPinVisualState.passed:
        // OLDER PASSED STOP: muted silver/gray
        bodyColor = const Color(0xFFCBD5E1);
        outlineColor = const Color(0xFF94A3B8);
        innerDotColor = const Color(0xFF64748B);
        innerDotRadius = 2.2;
      case StopPinVisualState.current:
        // LAST STOP (most recently arrived/passed): #FFC928 AMOMY accent yellow
        bodyColor = AppColors.accentYellow;
        outlineColor = Colors.white;
        innerDotColor = const Color(0xFF1E293B); // dark center detail
        innerDotRadius = 2.8;
      case StopPinVisualState.next:
        // NEXT STOP (approaching stop): #01589F AMOMY primary blue
        bodyColor = AppColors.primary;
        outlineColor = Colors.white;
        innerDotColor = Colors.white; // white center detail
        innerDotRadius = 3.0;
      case StopPinVisualState.selected:
        // Generic / Future Selected stop: white body with AMOMY blue prominent outline
        bodyColor = Colors.white;
        outlineColor = AppColors.primary;
        innerDotColor = AppColors.primary;
        innerDotRadius = 3.4;
      case StopPinVisualState.selectedLast:
        // Selected LAST stop: yellow body with white outline (preserving yellow identity)
        bodyColor = AppColors.accentYellow;
        outlineColor = Colors.white;
        innerDotColor = const Color(0xFF1E293B);
        innerDotRadius = 3.4;
      case StopPinVisualState.selectedNext:
        // Selected NEXT stop: blue body with white outline (preserving blue identity)
        bodyColor = AppColors.primary;
        outlineColor = Colors.white;
        innerDotColor = Colors.white;
        innerDotRadius = 3.4;
    }

    // 1. Ground contact shadow under pin tip (unclipped, soft oval)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, tipY + 0.6),
        width: isSelected ? 8.5 : 7.0,
        height: isSelected ? 3.4 : 2.8,
      ),
      shadowPaint,
    );

    // 2. Smooth teardrop pin geometry
    final pinPath = _createPinPath(cx, cy, headRadius, tipY);

    // 3. Pin body fill
    final pinPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    // 4. Subtle outline stroke
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pinPath, outlinePaint);

    // 5. Center landmark detail dot
    final centerDotPaint = Paint()
      ..color = innerDotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), innerDotRadius, centerDotPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(
      (logicalWidth * scale).toInt(),
      (logicalHeight * scale).toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: logicalWidth,
      height: logicalHeight,
      imagePixelRatio: scale,
    );

    _cache[key] = descriptor;
    return descriptor;
  }

  /// Convenience wrapper supporting boolean flags with backwards compatibility.
  static Future<BitmapDescriptor> getStopPinIcon({
    bool isCurrent = false,
    bool isNext = false,
    bool isPassed = false,
    bool isSelected = false,
  }) async {
    final StopPinVisualState state;
    if (isSelected) {
      state = StopPinVisualState.selected;
    } else if (isCurrent) {
      state = StopPinVisualState.current;
    } else if (isNext) {
      state = StopPinVisualState.next;
    } else if (isPassed) {
      state = StopPinVisualState.passed;
    } else {
      state = StopPinVisualState.normal;
    }
    return getStopPinIconForState(state);
  }

  /// Clean mathematical teardrop Pin geometry with tangent curves.
  static Path _createPinPath(double cx, double cy, double r, double tipY) {
    final path = Path();
    final dy = tipY - cy;
    final sinTheta = (r / dy).clamp(0.0, 1.0);
    final theta = math.asin(sinTheta);
    final cosTheta = math.cos(theta);

    // Tangent contact coordinates on head circle
    final rightTangentX = cx + r * cosTheta;
    final rightTangentY = cy + r * sinTheta;
    final leftTangentX = cx - r * cosTheta;
    final leftTangentY = cy + r * sinTheta;

    // Start at bottom tip point
    path.moveTo(cx, tipY);

    // Left tapered curve connecting tip smoothly to circular head
    path.cubicTo(
      cx - r * 0.15,
      tipY - (tipY - leftTangentY) * 0.35,
      leftTangentX + r * 0.05,
      leftTangentY + (tipY - leftTangentY) * 0.40,
      leftTangentX,
      leftTangentY,
    );

    // Rounded circular arc over the top of the pin head
    path.arcToPoint(
      Offset(rightTangentX, rightTangentY),
      radius: Radius.circular(r),
      largeArc: true,
      clockwise: true,
    );

    // Right tapered curve connecting circular head smoothly back to tip
    path.cubicTo(
      rightTangentX - r * 0.05,
      rightTangentY + (tipY - rightTangentY) * 0.40,
      cx + r * 0.15,
      tipY - (tipY - rightTangentY) * 0.35,
      cx,
      tipY,
    );

    path.close();
    return path;
  }
}
