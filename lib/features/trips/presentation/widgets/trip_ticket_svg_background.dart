import 'package:flutter/material.dart';

/// Official AMOMY Trip Ticket SVG vector shape component.
/// Replicates assets/trip_ticket.svg (Vector.svg, 939x475) with pixel-perfect resolution independence.
class TripTicketSvgBackground extends StatelessWidget {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double elevation;

  /// Original SVG aspect ratio (939.0 / 475.0 = ~1.977).
  static const double svgWidth = 939.0;
  static const double svgHeight = 475.0;
  static const double aspectRatio = svgWidth / svgHeight;

  /// Exact position of the vertical perforation divider line in SVG coordinates
  static const double dividerX = 235.9;

  /// Divider ratio relative to total width (235.9 / 939.0 ≈ 0.2512 = 25.12%)
  static const double dividerRatio = dividerX / svgWidth;

  final bool flipX;

  const TripTicketSvgBackground({
    super.key,
    this.fillColor = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0),
    this.borderWidth = 1.0,
    this.shadowColor = const Color(0x0F01589F),
    this.elevation = 4.0,
    this.flipX = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TripTicketPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadowColor: shadowColor,
        elevation: elevation,
        flipX: flipX,
      ),
    );
  }
}

class _TripTicketPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double elevation;
  final bool flipX;

  static Path? _cachedSvgPath;

  _TripTicketPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
    required this.elevation,
    required this.flipX,
  });

  static Path _getSvgPath() {
    if (_cachedSvgPath != null) return _cachedSvgPath!;
    final path = Path();
path.moveTo(938.63, 28.4801);
    path.lineTo(938.63, 0.0);
    path.lineTo(240.5, 0.0);
    path.lineTo(240.5, 18.6101);
    path.cubicTo(240.5, 19.8434, 240.01, 21.026, 239.138, 21.8981);
    path.cubicTo(238.266, 22.7701, 237.083, 23.26, 235.85, 23.26);
    path.cubicTo(234.617, 23.26, 233.434, 22.7701, 232.562, 21.8981);
    path.cubicTo(231.69, 21.026, 231.2, 19.8434, 231.2, 18.6101);
    path.lineTo(231.2, 0.0);
    path.lineTo(0.0400009, 0.0);
    path.lineTo(0.0400009, 28.4801);
    path.cubicTo(6.32298, 28.4801, 12.3486, 30.976, 16.7914, 35.4187);
    path.cubicTo(21.2341, 39.8614, 23.73, 45.8871, 23.73, 52.17);
    path.cubicTo(23.73, 58.453, 21.2341, 64.4787, 16.7914, 68.9214);
    path.cubicTo(12.3486, 73.3641, 6.32298, 75.8601, 0.0400009, 75.8601);
    path.lineTo(0.0400009, 89.4);
    path.cubicTo(6.32298, 89.4, 12.3486, 91.896, 16.7914, 96.3387);
    path.cubicTo(21.2341, 100.781, 23.73, 106.807, 23.73, 113.09);
    path.cubicTo(23.73, 119.373, 21.2341, 125.399, 16.7914, 129.841);
    path.cubicTo(12.3486, 134.284, 6.32298, 136.78, 0.0400009, 136.78);
    path.lineTo(0.0400009, 150.32);
    path.cubicTo(3.15186, 150.319, 6.23348, 150.931, 9.10884, 152.12);
    path.cubicTo(11.9842, 153.31, 14.5969, 155.055, 16.7978, 157.255);
    path.cubicTo(18.9987, 159.455, 20.7446, 162.067, 21.9358, 164.942);
    path.cubicTo(23.1269, 167.817, 23.74, 170.898, 23.74, 174.01);
    path.cubicTo(23.7315, 176.273, 23.3946, 178.523, 22.74, 180.69);
    path.cubicTo(21.2961, 185.601, 18.2999, 189.911, 14.2003, 192.976);
    path.cubicTo(10.1008, 196.041, 5.11852, 197.695, 0.0, 197.69);
    path.lineTo(0.0, 211.23);
    path.cubicTo(6.28298, 211.23, 12.3086, 213.726, 16.7514, 218.169);
    path.cubicTo(21.1941, 222.611, 23.69, 228.637, 23.69, 234.92);
    path.cubicTo(23.69, 241.203, 21.1941, 247.229, 16.7514, 251.671);
    path.cubicTo(12.3086, 256.114, 6.28298, 258.61, 0.0, 258.61);
    path.lineTo(0.0, 272.15);
    path.cubicTo(6.28298, 272.15, 12.3086, 274.646, 16.7514, 279.089);
    path.cubicTo(21.1941, 283.531, 23.69, 289.557, 23.69, 295.84);
    path.cubicTo(23.69, 302.123, 21.1941, 308.149, 16.7514, 312.591);
    path.cubicTo(12.3086, 317.034, 6.28298, 319.53, 0.0, 319.53);
    path.lineTo(0.0, 333.07);
    path.cubicTo(6.28298, 333.07, 12.3086, 335.566, 16.7514, 340.009);
    path.cubicTo(21.1941, 344.451, 23.69, 350.477, 23.69, 356.76);
    path.cubicTo(23.69, 363.043, 21.1941, 369.069, 16.7514, 373.511);
    path.cubicTo(12.3086, 377.954, 6.28298, 380.45, 0.0, 380.45);
    path.lineTo(0.0, 393.99);
    path.cubicTo(6.28033, 393.99, 12.3034, 396.485, 16.7443, 400.926);
    path.cubicTo(21.1851, 405.367, 23.68, 411.39, 23.68, 417.67);
    path.cubicTo(23.68, 423.95, 21.1851, 429.973, 16.7443, 434.414);
    path.cubicTo(12.3034, 438.855, 6.28033, 441.35, 0.0, 441.35);
    path.lineTo(0.0, 474.86);
    path.lineTo(231.25, 474.86);
    path.lineTo(231.25, 455.17);
    path.cubicTo(231.25, 453.937, 231.74, 452.754, 232.612, 451.882);
    path.cubicTo(233.484, 451.01, 234.667, 450.52, 235.9, 450.52);
    path.cubicTo(237.133, 450.52, 238.316, 451.01, 239.188, 451.882);
    path.cubicTo(240.06, 452.754, 240.55, 453.937, 240.55, 455.17);
    path.lineTo(240.55, 474.86);
    path.lineTo(938.68, 474.86);
    path.lineTo(938.68, 441.36);
    path.cubicTo(932.4, 441.36, 926.377, 438.865, 921.936, 434.424);
    path.cubicTo(917.495, 429.983, 915.0, 423.96, 915.0, 417.68);
    path.cubicTo(915.0, 411.4, 917.495, 405.377, 921.936, 400.936);
    path.cubicTo(926.377, 396.495, 932.4, 394.0, 938.68, 394.0);
    path.lineTo(938.68, 380.46);
    path.cubicTo(932.397, 380.46, 926.371, 377.964, 921.929, 373.521);
    path.cubicTo(917.486, 369.079, 914.99, 363.053, 914.99, 356.77);
    path.cubicTo(914.99, 350.487, 917.486, 344.461, 921.929, 340.019);
    path.cubicTo(926.371, 335.576, 932.397, 333.08, 938.68, 333.08);
    path.lineTo(938.68, 319.56);
    path.cubicTo(932.397, 319.56, 926.371, 317.064, 921.929, 312.621);
    path.cubicTo(917.486, 308.179, 914.99, 302.153, 914.99, 295.87);
    path.cubicTo(914.99, 289.587, 917.486, 283.561, 921.929, 279.119);
    path.cubicTo(926.371, 274.676, 932.397, 272.18, 938.68, 272.18);
    path.lineTo(938.68, 258.64);
    path.cubicTo(932.397, 258.64, 926.371, 256.144, 921.929, 251.701);
    path.cubicTo(917.486, 247.259, 914.99, 241.233, 914.99, 234.95);
    path.cubicTo(914.99, 228.667, 917.486, 222.641, 921.929, 218.199);
    path.cubicTo(926.371, 213.756, 932.397, 211.26, 938.68, 211.26);
    path.lineTo(938.68, 197.72);
    path.cubicTo(932.397, 197.72, 926.371, 195.224, 921.929, 190.781);
    path.cubicTo(917.486, 186.339, 914.99, 180.313, 914.99, 174.03);
    path.cubicTo(914.99, 167.747, 917.486, 161.721, 921.929, 157.279);
    path.cubicTo(926.371, 152.836, 932.397, 150.34, 938.68, 150.34);
    path.lineTo(938.68, 136.8);
    path.cubicTo(932.397, 136.8, 926.371, 134.304, 921.929, 129.861);
    path.cubicTo(917.486, 125.419, 914.99, 119.393, 914.99, 113.11);
    path.cubicTo(914.99, 106.827, 917.486, 100.801, 921.929, 96.3586);
    path.cubicTo(926.371, 91.9159, 932.397, 89.42, 938.68, 89.42);
    path.lineTo(938.68, 75.8601);
    path.cubicTo(932.397, 75.8601, 926.371, 73.3641, 921.929, 68.9214);
    path.cubicTo(917.486, 64.4787, 914.99, 58.453, 914.99, 52.17);
    path.cubicTo(914.99, 45.8871, 917.486, 39.8614, 921.929, 35.4187);
    path.cubicTo(926.371, 30.976, 932.397, 28.4801, 938.68, 28.4801);
    path.lineTo(938.63, 28.4801);
    path.close();
    path.moveTo(231.25, 39.9);
    path.cubicTo(231.25, 38.6668, 231.74, 37.4841, 232.612, 36.6121);
    path.cubicTo(233.484, 35.74, 234.667, 35.25, 235.9, 35.25);
    path.cubicTo(237.133, 35.25, 238.316, 35.74, 239.188, 36.6121);
    path.cubicTo(240.06, 37.4841, 240.55, 38.6668, 240.55, 39.9);
    path.lineTo(240.55, 101.67);
    path.cubicTo(240.55, 102.903, 240.06, 104.086, 239.188, 104.958);
    path.cubicTo(238.316, 105.83, 237.133, 106.32, 235.9, 106.32);
    path.cubicTo(234.667, 106.32, 233.484, 105.83, 232.612, 104.958);
    path.cubicTo(231.74, 104.086, 231.25, 102.903, 231.25, 101.67);
    path.lineTo(231.25, 39.9);
    path.close();
    path.moveTo(231.25, 122.96);
    path.cubicTo(231.25, 121.727, 231.74, 120.544, 232.612, 119.672);
    path.cubicTo(233.484, 118.8, 234.667, 118.31, 235.9, 118.31);
    path.cubicTo(237.133, 118.31, 238.316, 118.8, 239.188, 119.672);
    path.cubicTo(240.06, 120.544, 240.55, 121.727, 240.55, 122.96);
    path.lineTo(240.55, 184.73);
    path.cubicTo(240.55, 185.963, 240.06, 187.146, 239.188, 188.018);
    path.cubicTo(238.316, 188.89, 237.133, 189.38, 235.9, 189.38);
    path.cubicTo(234.667, 189.38, 233.484, 188.89, 232.612, 188.018);
    path.cubicTo(231.74, 187.146, 231.25, 185.963, 231.25, 184.73);
    path.lineTo(231.25, 122.96);
    path.close();
    path.moveTo(231.25, 205.96);
    path.cubicTo(231.25, 204.727, 231.74, 203.544, 232.612, 202.672);
    path.cubicTo(233.484, 201.8, 234.667, 201.31, 235.9, 201.31);
    path.cubicTo(237.133, 201.31, 238.316, 201.8, 239.188, 202.672);
    path.cubicTo(240.06, 203.544, 240.55, 204.727, 240.55, 205.96);
    path.lineTo(240.55, 267.73);
    path.cubicTo(240.55, 268.963, 240.06, 270.146, 239.188, 271.018);
    path.cubicTo(238.316, 271.89, 237.133, 272.38, 235.9, 272.38);
    path.cubicTo(234.667, 272.38, 233.484, 271.89, 232.612, 271.018);
    path.cubicTo(231.74, 270.146, 231.25, 268.963, 231.25, 267.73);
    path.lineTo(231.25, 205.96);
    path.close();
    path.moveTo(240.55, 433.85);
    path.cubicTo(240.55, 435.083, 240.06, 436.266, 239.188, 437.138);
    path.cubicTo(238.316, 438.01, 237.133, 438.5, 235.9, 438.5);
    path.cubicTo(234.667, 438.5, 233.484, 438.01, 232.612, 437.138);
    path.cubicTo(231.74, 436.266, 231.25, 435.083, 231.25, 433.85);
    path.lineTo(231.25, 372.08);
    path.cubicTo(231.25, 370.847, 231.74, 369.664, 232.612, 368.792);
    path.cubicTo(233.484, 367.92, 234.667, 367.43, 235.9, 367.43);
    path.cubicTo(237.133, 367.43, 238.316, 367.92, 239.188, 368.792);
    path.cubicTo(240.06, 369.664, 240.55, 370.847, 240.55, 372.08);
    path.lineTo(240.55, 433.85);
    path.close();
    path.moveTo(240.55, 350.79);
    path.cubicTo(240.55, 352.023, 240.06, 353.206, 239.188, 354.078);
    path.cubicTo(238.316, 354.95, 237.133, 355.44, 235.9, 355.44);
    path.cubicTo(234.667, 355.44, 233.484, 354.95, 232.612, 354.078);
    path.cubicTo(231.74, 353.206, 231.25, 352.023, 231.25, 350.79);
    path.lineTo(231.25, 289.02);
    path.cubicTo(231.25, 287.787, 231.74, 286.604, 232.612, 285.732);
    path.cubicTo(233.484, 284.86, 234.667, 284.37, 235.9, 284.37);
    path.cubicTo(237.133, 284.37, 238.316, 284.86, 239.188, 285.732);
    path.cubicTo(240.06, 286.604, 240.55, 287.787, 240.55, 289.02);
    path.lineTo(240.55, 350.79);
    path.close();
    _cachedSvgPath = path;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / TripTicketSvgBackground.svgWidth;
    final scaleY = size.height / TripTicketSvgBackground.svgHeight;

    canvas.save();
    if (flipX) {
      canvas.translate(size.width, 0);
      canvas.scale(-scaleX, scaleY);
    } else {
      canvas.scale(scaleX, scaleY);
    }

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
  bool shouldRepaint(covariant _TripTicketPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation ||
        oldDelegate.flipX != flipX;
  }
}
