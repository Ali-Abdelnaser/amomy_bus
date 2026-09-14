import 'package:flutter/material.dart';

/// Renders SVG vector paths cleanly using Flutter's built-in [CustomPainter].
/// This renders sharp, resolution-independent vector graphics for the 4 bottom nav icons:
/// - Home (`assets/home.svg`)
/// - Trips (`assets/trip.svg`)
/// - Wallet (`assets/wallet.svg`)
/// - Profile (`assets/profile.svg`)
enum NavSvgType { home, trip, wallet, profile }

class NavSvgIcon extends StatelessWidget {
  final NavSvgType type;
  final Color color;
  final double size;

  const NavSvgIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NavSvgPainter(type: type, color: color),
      ),
    );
  }
}

class _NavSvgPainter extends CustomPainter {
  final NavSvgType type;
  final Color color;

  _NavSvgPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case NavSvgType.home:
        _paintHome(canvas, size);
      case NavSvgType.trip:
        _paintTrip(canvas, size);
      case NavSvgType.wallet:
        _paintWallet(canvas, size);
      case NavSvgType.profile:
        _paintProfile(canvas, size);
    }
  }

  void _paintHome(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer house path
    final path1 = Path();
    path1.moveTo(21, 19);
    path1.lineTo(21, 12.267);
    path1.cubicTo(21, 11.7245, 20.8896, 11.1876, 20.6756, 10.689);
    path1.cubicTo(20.4616, 10.1905, 20.1483, 9.74069, 19.755, 9.36701);
    path1.lineTo(13.378, 3.31001);
    path1.cubicTo(13.0063, 2.9569, 12.5132, 2.76001, 12.0005, 2.76001);
    path1.cubicTo(11.4878, 2.76001, 10.9947, 2.9569, 10.623, 3.31001);
    path1.lineTo(4.245, 9.36701);
    path1.cubicTo(3.85165, 9.74069, 3.53844, 10.1905, 3.3244, 10.689);
    path1.cubicTo(3.11037, 11.1876, 3, 11.7245, 3, 12.267);
    path1.lineTo(3, 19);
    path1.cubicTo(3, 19.5304, 3.21071, 20.0392, 3.58579, 20.4142);
    path1.cubicTo(3.96086, 20.7893, 4.46957, 21, 5, 21);
    path1.lineTo(19, 21);
    path1.cubicTo(19.5304, 21, 20.0391, 20.7893, 20.4142, 20.4142);
    path1.cubicTo(20.7893, 20.0392, 21, 19.5304, 21, 19);
    path1.close();
    canvas.drawPath(path1, strokePaint);

    // Inner door path
    final path2 = Path();
    path2.moveTo(9, 15);
    path2.cubicTo(9, 14.4696, 9.21071, 13.9609, 9.58579, 13.5858);
    path2.cubicTo(9.96086, 13.2107, 10.4696, 13, 11, 13);
    path2.lineTo(13, 13);
    path2.cubicTo(13.5304, 13, 14.0391, 13.2107, 14.4142, 13.5858);
    path2.cubicTo(14.7893, 13.9609, 15, 14.4696, 15, 15);
    path2.lineTo(15, 21);
    path2.lineTo(9, 21);
    path2.close();
    canvas.drawPath(path2, strokePaint);

    canvas.restore();
  }

  void _paintTrip(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Road lines & location point from trip.svg
    canvas.drawLine(
      const Offset(12.5, 10.5),
      const Offset(18.0, 10.5),
      strokePaint,
    );
    canvas.drawLine(
      const Offset(16.0, 18.0),
      const Offset(13.0, 22.0),
      strokePaint,
    );
    canvas.drawLine(
      const Offset(13.0, 22.0),
      const Offset(8.0, 22.0),
      strokePaint,
    );
    canvas.drawLine(
      const Offset(13.0, 22.0),
      const Offset(18.0, 22.0),
      strokePaint,
    );

    final mainPath = Path();
    mainPath.moveTo(8.482, 18);
    mainPath.lineTo(17.972, 18);
    mainPath.cubicTo(19.092, 18, 20.0, 17.108, 20.0, 16.007);
    mainPath.cubicTo(20.0, 14.5, 17.972, 14.014, 17.972, 14.014);
    mainPath.cubicTo(17.972, 14.014, 14.284, 12.596, 10.0, 14);
    mainPath.cubicTo(10.0, 14, 9.861, 8.873, 7.71, 3.17);
    mainPath.cubicTo(7.285, 2.046, 5.901, 1.662, 4.885, 2.327);
    mainPath.cubicTo(4.558, 2.538, 4.303, 2.843, 4.152, 3.201);
    mainPath.cubicTo(4.002, 3.560, 3.962, 3.955, 4.039, 4.337);
    mainPath.lineTo(6.493, 16.397);
    mainPath.cubicTo(6.589, 16.852, 6.839, 17.260, 7.202, 17.552);
    mainPath.cubicTo(7.564, 17.844, 8.016, 18.002, 8.482, 18);
    mainPath.close();
    canvas.drawPath(mainPath, strokePaint);

    canvas.restore();
  }

  void _paintWallet(Canvas canvas, Size size) {
    final scale = size.width / 16.0;
    canvas.save();
    canvas.scale(scale, scale);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Wallet body & flap from wallet.svg
    final path = Path();
    path.moveTo(7.954, 1.372);
    path.cubicTo(8.036, 1.268, 8.138, 1.182, 8.254, 1.119);
    path.cubicTo(8.370, 1.055, 8.498, 1.015, 8.629, 1.001);
    path.cubicTo(8.761, 0.987, 8.894, 1.000, 9.020, 1.038);
    path.cubicTo(9.147, 1.075, 9.265, 1.138, 9.368, 1.222);
    path.lineTo(12.63, 3.886);
    path.cubicTo(12.809, 4.032, 12.932, 4.236, 12.978, 4.463);
    path.cubicTo(13.023, 4.690, 12.988, 4.926, 12.88, 5.131);
    path.cubicTo(12.594, 5.043, 12.298, 4.999, 12, 5.0);
    path.lineTo(11.7, 5.0);
    path.lineTo(11.998, 4.66);
    path.lineTo(10.28, 3.257);
    path.lineTo(8.863, 5.001);
    path.lineTo(7.574, 5.001);
    path.lineTo(9.505, 2.625);
    path.lineTo(8.735, 1.996);
    path.lineTo(6.337, 5.0);
    path.lineTo(5.057, 5.0);
    path.close();

    // Lower wallet body
    final bodyPath = Path();
    bodyPath.moveTo(3, 5.5);
    bodyPath.cubicTo(3, 5.367, 3.052, 5.240, 3.146, 5.146);
    bodyPath.cubicTo(3.240, 5.052, 3.367, 5.0, 3.5, 5.0);
    bodyPath.lineTo(4.058, 5.0);
    bodyPath.lineTo(4.853, 4.0);
    bodyPath.lineTo(3.5, 4.0);
    bodyPath.cubicTo(3.102, 4.0, 2.720, 4.158, 2.439, 4.439);
    bodyPath.cubicTo(2.158, 4.720, 2, 5.102, 2, 5.5);
    bodyPath.lineTo(2, 11.5);
    bodyPath.cubicTo(2, 12.163, 2.263, 12.799, 2.732, 13.267);
    bodyPath.cubicTo(3.201, 13.736, 3.836, 14, 4.5, 14);
    bodyPath.lineTo(12, 14);
    bodyPath.cubicTo(12.530, 14, 13.039, 13.789, 13.414, 13.414);
    bodyPath.cubicTo(13.789, 13.039, 14, 12.530, 14, 12);
    bodyPath.lineTo(14, 8.0);
    bodyPath.cubicTo(14, 7.469, 13.789, 6.960, 13.414, 6.585);
    bodyPath.cubicTo(13.039, 6.210, 12.530, 6.0, 12, 6.0);
    bodyPath.lineTo(3.5, 6.0);
    bodyPath.cubicTo(3.367, 6.0, 3.240, 5.947, 3.146, 5.853);
    bodyPath.cubicTo(3.052, 5.759, 3, 5.632, 3, 5.5);
    bodyPath.close();

    // Card inset line
    bodyPath.moveTo(3, 11.5);
    bodyPath.lineTo(3, 6.915);
    bodyPath.cubicTo(3.157, 6.971, 3.324, 6.999, 3.5, 7.0);
    bodyPath.lineTo(12, 7.0);
    bodyPath.cubicTo(12.265, 7.0, 12.519, 7.105, 12.707, 7.292);
    bodyPath.cubicTo(12.894, 7.480, 13, 7.734, 13, 8.0);
    bodyPath.lineTo(13, 12);
    bodyPath.cubicTo(13, 12.265, 12.894, 12.519, 12.707, 12.707);
    bodyPath.cubicTo(12.519, 12.894, 12.265, 13, 12, 13);
    bodyPath.lineTo(4.5, 13);
    bodyPath.cubicTo(4.102, 13, 3.720, 12.842, 3.439, 12.560);
    bodyPath.cubicTo(3.158, 12.279, 3, 11.897, 3, 11.5);
    bodyPath.close();

    // Center lock circle
    bodyPath.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 2, 1.5),
        const Radius.circular(0.75),
      ),
    );

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(bodyPath, fillPaint);

    canvas.restore();
  }

  void _paintProfile(Canvas canvas, Size size) {
    final scale = size.width / 16.0;
    canvas.save();
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head circle / teardrop from profile.svg
    final headPath = Path();
    headPath.moveTo(8, 10);
    headPath.cubicTo(9.5, 10, 11, 8, 11, 5.5);
    headPath.cubicTo(11, 3, 10, 1.5, 8, 1.5);
    headPath.cubicTo(6, 1.5, 5, 3, 5, 5.5);
    headPath.cubicTo(5, 8, 6.5, 10, 8, 10);
    headPath.close();
    canvas.drawPath(headPath, strokePaint);

    // Body shoulders curve
    final shouldersPath = Path();
    shouldersPath.moveTo(8, 10);
    shouldersPath.cubicTo(11, 10, 14, 10.5, 14, 15);
    shouldersPath.lineTo(2, 15);
    shouldersPath.cubicTo(2, 10.5, 5, 10, 8, 10);
    shouldersPath.close();
    canvas.drawPath(shouldersPath, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavSvgPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
